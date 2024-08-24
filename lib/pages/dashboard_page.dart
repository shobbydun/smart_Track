import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_track/components/my_list_tile.dart';
import 'package:smart_track/database/firestore_services.dart';
import 'package:smart_track/pages/inventory_management_screen.dart';
import 'package:smart_track/pages/product_management_screen.dart';
import 'package:smart_track/pages/sales_management_screen.dart';

class DashboardPage extends StatefulWidget {
  final FirestoreServices firestoreServices;

  const DashboardPage({Key? key, required this.firestoreServices}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  User? user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  String? businessName;
  List<Product> _products = [];
  String? _selectedProductId;
  TextEditingController _quantityController = TextEditingController();
  bool _isDialogVisible = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _fetchBusinessName();
      _fetchProducts();
    } else {
      print("No user is currently logged in.");
    }
  }

  Future<void> _fetchBusinessName() async {
    try {
      final name = await widget.firestoreServices.getBusinessName();
      setState(() {
        businessName = name;
      });
    } catch (e) {
      print("Error fetching business name: $e");
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final productsStream = widget.firestoreServices.getProducts();
      productsStream.listen((products) {
        setState(() {
          _products = products;
        });
      });
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

Future<void> _showAddSaleDialog() async {
  if (_isDialogVisible) return; // Prevent showing multiple dialogs

  setState(() {
    _isDialogVisible = true;
  });

  // Clear previous selections
  _selectedProductId = null;
  _quantityController.clear();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      Product? selectedProduct;
      int quantity = 1;

      return AlertDialog(
        title: Text('Add New Sale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownSearch<Product>(
              items: _products,
              itemAsString: (Product p) => p.name,
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: "Select Product",
                  hintText: "Search Product",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              onChanged: (Product? product) {
                setState(() {
                  _selectedProductId = product?.id;
                  selectedProduct = product;
                });
              },
              selectedItem: selectedProduct,
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search Product',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                menuProps: MenuProps(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                quantity = int.tryParse(value) ?? 1;
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isDialogVisible = false;
              });
            },
          ),
          ElevatedButton(
            child: Text('Add'),
            onPressed: () async {
              if (_selectedProductId != null && quantity > 0) {
                final selectedProduct = _products.firstWhere(
                  (p) => p.id == _selectedProductId,
                  orElse: () => Product(
                    id: '',
                    name: '',
                    stock: 0,
                    price: 0.0,
                    timestamp: Timestamp.now(),
                  ),
                );

                if (selectedProduct.stock >= quantity) {
                  await widget.firestoreServices.addSale(_selectedProductId!, quantity);
                  Navigator.of(context).pop();
                  setState(() {
                    _isDialogVisible = false;
                    _selectedProductId = null; // Clear the selected product
                    _quantityController.clear(); // Clear the quantity field
                  });
                } else {
                  Navigator.of(context).pop();
                  setState(() {
                    _isDialogVisible = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quantity exceeds available stock.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      );
    },
  );
}


  Future<void> _showEditSaleDialog(String saleId) async {
    if (_isDialogVisible) return; // Prevent showing multiple dialogs

    setState(() {
      _isDialogVisible = true;
    });

    Sale? sale;
    Product? selectedProduct;

    try {
      sale = await widget.firestoreServices.getSaleById(saleId);
      if (sale != null) {
        selectedProduct = _products.firstWhere(
          (p) => p.id == sale?.productId,
          orElse: () => Product(
            id: '',
            name: 'Unknown Product',
            stock: 0,
            price: 0.0,
            timestamp: Timestamp.now(),
          ),
        );
        _quantityController.text = sale.quantity.toString();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching sale details.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Sale'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (selectedProduct != null)
                DropdownSearch<Product>(
                  items: _products,
                  itemAsString: (Product p) => p.name,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Select Product",
                      hintText: "Search Product",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  onChanged: (Product? product) {
                    setState(() {
                      _selectedProductId = product?.id;
                      selectedProduct = product;
                    });
                  },
                  selectedItem: selectedProduct,
                ),
              SizedBox(height: 16),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              if (selectedProduct != null)
                Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Selected Product: ${selectedProduct!.name}',
                    style: TextStyle(fontSize: 16),
                  ),
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
            TextButton(
              child: Text('Update Sale'),
              onPressed: () async {
                if (_selectedProductId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select a product.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                try {
                  await widget.firestoreServices.updateSale(
                    saleId,
                    _selectedProductId!,
                    int.tryParse(_quantityController.text) ?? 1,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sale updated successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating sale: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() {
                    _isDialogVisible = false;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

Future<void> deleteSale(String saleId) async {
  bool? confirmDelete = await _showConfirmationDialog();

  if (confirmDelete == true) {
    try {
      await widget.firestoreServices.deleteSale(saleId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sale deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting sale: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<bool?> _showConfirmationDialog() async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this sale? This action cannot be undone.'),
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


  Stream<List<Sale>> _streamSalesToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return widget.firestoreServices.getSalesByDate(startOfDay, endOfDay);
  }

  Stream<double> _streamTotalSalesToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return widget.firestoreServices.getTotalSalesByDate(startOfDay, endOfDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(189, 189, 189, 1),
      body: _getBodyContent(),
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[400],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.insert_chart, 1),
            SizedBox(width: 48), // Space for the center button
            _buildNavItem(Icons.inventory, 2),
            _buildNavItem(Icons.attach_money, 3),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: _showAddSaleDialog,
              elevation: 8.0,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? Colors.green.withOpacity(0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          color: _selectedIndex == index ? Colors.green : Colors.black,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return InventoryManagementScreen(firestoreServices: widget.firestoreServices);
      case 2:
        return ProductManagementScreen(firestoreServices: widget.firestoreServices);
      case 3:
        return SalesManagementScreen(firestoreServices: widget.firestoreServices);
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (businessName != null)
                Text(
                  '${businessName?.toUpperCase()} Investments',
                  style: GoogleFonts.libreBaskerville(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.person),
                      onPressed: () => Navigator.pushNamed(context, '/user_profile_page'),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => Navigator.pushNamed(context, '/notifications_page'),
                  ),
                ],
              ),
            ],
          ),
        ),
        StreamBuilder<double>(
          stream: _streamTotalSalesToday(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            }

            final totalSales = snapshot.data ?? 0.0;

            return Container(
              padding: EdgeInsets.all(26.0),
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.2),
                    spreadRadius: 3,
                    blurRadius: 3,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Sales Today:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Kshs ${totalSales.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Text(
            'Recent Sales:',
            style: GoogleFonts.libreBaskerville(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Sale>>(
            stream: _streamSalesToday(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final sales = snapshot.data ?? [];

              if (sales.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No sales today.',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  final product = _products.firstWhere(
                    (p) => p.id == sale.productId,
                    orElse: () => Product(
                      id: '',
                      name: 'Unknown Product',
                      stock: 0,
                      price: 0.0,
                      timestamp: Timestamp.now(),
                    ),
                  );
                  return MyListTile(
                    id: sale.id,
                    name: product.name, // Use product name instead of sale.productName
                    price: product.price, // Use product price
                    timestamp: sale.timestamp,
                    quantity: sale.quantity,
                    onEdit: (id, newName, newPrice, quantity) {
                      _showEditSaleDialog(id);
                    },
                    onDelete: deleteSale,
                    title: Text('Product: ${product.name}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
