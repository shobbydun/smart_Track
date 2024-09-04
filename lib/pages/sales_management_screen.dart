import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smart_track/database/firestore_services.dart';

class SalesManagementScreen extends StatefulWidget {
  final FirestoreServices firestoreServices;
  const SalesManagementScreen({super.key, required this.firestoreServices});

  @override
  _SalesManagementScreenState createState() => _SalesManagementScreenState();
}

class _SalesManagementScreenState extends State<SalesManagementScreen> {
  late final FirestoreServices _firestoreServices;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _selectedDate = DateTime.now();
  double _totalSales = 0.0;
  Map<String, double> _productPrices = {};
  Map<String, String> _productNames = {}; // Store product names

  @override
  void initState() {
    super.initState();
    _firestoreServices = widget.firestoreServices;
    _fetchProductPrices();
    _fetchProductNames(); // Fetch product names on initialization
  }

  void _fetchProductPrices() async {
    try {
      final productsStream = _firestoreServices.getProducts();
      productsStream.listen((products) {
        setState(() {
          _productPrices = {for (var p in products) p.id: p.price};
        });
      });
    } catch (e) {
      print("Error fetching product prices: $e");
    }
  }

  void _fetchProductNames() async {
    try {
      final productsStream = _firestoreServices.getProducts();
      productsStream.listen((products) {
        setState(() {
          _productNames = {for (var p in products) p.id: p.name};
        });
      });
    } catch (e) {
      print("Error fetching product names: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[400],
        title: Text('Sales Management', style: GoogleFonts.libreBaskerville()),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateFilter(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<double>(
              stream: _streamTotalSalesForSelectedDate(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final totalSales = snapshot.data ?? 0.0;
                return Text(
                  'Total Sales for ${DateFormat('yyyy-MM-dd').format(_selectedDate)}: Kshs ${totalSales.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Sale>>(
              stream: _fetchSales(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No sales available.'));
                }

                final sales = snapshot.data!;

                return ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final productName = _productNames[sale.productId] ?? 'Unknown Product';
                    final productPrice = _productPrices[sale.productId] ?? 0.0;
                    final salePrice = sale.quantity * productPrice;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[500],
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text('Product: $productName'),
                        subtitle: Text('Kshs ${salePrice.toStringAsFixed(2)}'),
                        trailing: Text(DateFormat('yyyy-MM-dd')
                            .format(sale.timestampAsDateTime)),
                        onTap: () {},
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Sale>> _fetchSales() {
    final startOfDay = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0, 0);
    final endOfDay = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, 23, 59, 59, 999);

    return _firestoreServices.getSalesByDate(startOfDay, endOfDay);
  }

  Stream<double> _streamTotalSalesForSelectedDate() {
    return _fetchSales().map((sales) {
      return sales.fold(0.0, (sum, sale) {
        final productPrice = _productPrices[sale.productId] ?? 0.0;
        return sum + (sale.quantity * productPrice);
      });
    });
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );

    if (selectedDate != null && selectedDate != _selectedDate) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }
}
