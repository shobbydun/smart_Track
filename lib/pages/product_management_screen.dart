import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_track/database/firestore_services.dart';
import 'package:smart_track/pages/inventory_management_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  final FirestoreServices firestoreServices;
  const ProductManagementScreen({super.key, required this.firestoreServices});

  @override
  _ProductManagementScreenState createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  late final FirestoreServices _firestoreServices;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _firestoreServices = widget.firestoreServices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Products Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InventoryManagementScreen(firestoreServices: _firestoreServices),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _firestoreServices.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No products found.'));
          }

          final products = snapshot.data!;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16.0),
                  title: Text(
                    product.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock: ${product.stock}',
                        style: TextStyle(
                          color: product.stock < 10 ? Colors.red : Colors.black,
                          fontSize: 16.0,
                        ),
                      ),
                      Text(
                        'Price: Kshs ${product.price.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditProductDialog(product);
                      } else if (value == 'delete') {
                        _deleteProduct(product.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showAddProductDialog,
      ),
    );
  }

  void _showAddProductDialog() {
    String name = '';
    int stock = 0;
    double price = 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (value) {
                  name = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  stock = int.tryParse(value) ?? 0;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  price = double.tryParse(value) ?? 0.0;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () async {
                if (name.isNotEmpty && stock >= 0 && price > 0) {
                  await _firestoreServices.addProduct(name, stock, price);
                  Navigator.of(context).pop();
                } else {
                  // Show error if invalid input
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please provide valid inputs')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(Product product) {
    final TextEditingController nameController = TextEditingController(text: product.name);
    final TextEditingController stockController = TextEditingController(text: product.stock.toString());
    final TextEditingController priceController = TextEditingController(text: product.price.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: stockController,
                decoration: InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () async {
                final name = nameController.text;
                final stock = int.tryParse(stockController.text) ?? 0;
                final price = double.tryParse(priceController.text) ?? 0.0;

                if (name.isNotEmpty && stock >= 0 && price > 0) {
                  await _firestoreServices.updateProduct(product.id, name, stock, price);
                  Navigator.of(context).pop();
                } else {
                  // Show error if invalid input
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please provide valid inputs')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId) async {
    final bool? shouldDelete = await _showDeleteConfirmationDialog();
    if (shouldDelete ?? false) {
      await _firestoreServices.deleteProduct(productId);
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this product?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
