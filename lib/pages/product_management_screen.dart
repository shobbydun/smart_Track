import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_track/database/firestore_services.dart';
import 'package:smart_track/pages/inventory_management_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  final FirestoreServices firestoreServices;

  const ProductManagementScreen({Key? key, required this.firestoreServices}) : super(key: key);

  @override
  _ProductManagementScreenState createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  late final FirestoreServices _firestoreServices;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  String _searchQuery = '';
  String _filter = 'Name'; // Default filter
  bool _isProcessing = false; // Added to manage state during async operations

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
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _firestoreServices.getProducts(), // Use your method to get all products
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

                final products = snapshot.data!
                    .where((product) => product.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

                // Apply filtering based on selected filter
                switch (_filter) {
                  case 'Stock Low to High':
                    products.sort((a, b) => a.stock.compareTo(b.stock));
                    break;
                  case 'Stock High to Low':
                    products.sort((a, b) => b.stock.compareTo(a.stock));
                    break;
                  case 'Price Low to High':
                    products.sort((a, b) => a.price.compareTo(b.price));
                    break;
                  case 'Price High to Low':
                    products.sort((a, b) => b.price.compareTo(a.price));
                    break;
                  case 'Date Added':
                    products.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                    break;
                  default:
                    break;
                }

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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _isProcessing ? null : _showAddProductDialog, // Prevent multiple dialogs if processing
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          SizedBox(width: 8.0),
          DropdownButton<String>(
            value: _filter,
            onChanged: (String? newValue) {
              setState(() {
                _filter = newValue!;
              });
            },
            items: <String>[
              'Name',
              'Stock Low to High',
              'Stock High to Low',
              'Price Low to High',
              'Price High to Low',
              'Date Added'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            underline: SizedBox(),
            isExpanded: false,
          ),
        ],
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
                  setState(() {
                    _isProcessing = true;
                  });
                  try {
                    await _firestoreServices.addProduct(name, stock, price);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Product added successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add product: $e')),
                    );
                  } finally {
                    setState(() {
                      _isProcessing = false;
                    });
                    Navigator.of(context).pop();
                  }
                } else {
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
                  setState(() {
                    _isProcessing = true;
                  });
                  try {
                    await _firestoreServices.updateProduct(product.id, name, stock, price);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Product updated successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update product: $e')),
                    );
                  } finally {
                    setState(() {
                      _isProcessing = false;
                    });
                    Navigator.of(context).pop();
                  }
                } else {
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
      setState(() {
        _isProcessing = true;
      });
      try {
        await _firestoreServices.deleteProduct(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product: $e')),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
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
