import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_track/components/chart_colors.dart';
import 'package:smart_track/database/firestore_services.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class InventoryManagementScreen extends StatefulWidget {
  final FirestoreServices firestoreServices;

  const InventoryManagementScreen({Key? key, required this.firestoreServices})
      : super(key: key);

  @override
  _InventoryManagementScreenState createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  List<Product> _products = [];
  List<Sale> _sales = [];
  String _selectedTimeline = 'Weekly';
  double _totalSalesForSelectedTimeline = 0.0;
  int _totalStockForSelectedTimeline = 0;
  double _currentStockValue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchProductData();
    _fetchSalesData();
  }

  void _fetchProductData() async {
    try {
      final productsStream = widget.firestoreServices.getProducts();
      productsStream.listen((productsSnapshot) {
        setState(() {
          _products = productsSnapshot;
          _updateTotalStockForSelectedTimeline();
        });
      });
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  void _fetchSalesData() async {
    try {
      final salesStream = widget.firestoreServices.getSales();
      salesStream.listen((salesSnapshot) {
        setState(() {
          _sales = salesSnapshot;
          _updateTotalSalesForSelectedTimeline();
        });
      });
    } catch (e) {
      print("Error fetching sales: $e");
    }
  }

  void _updateTotalSalesForSelectedTimeline() {
    final now = DateTime.now();
    final startOfTimeline = _getStartOfTimeline(now, _selectedTimeline);
    final endOfTimeline = _getEndOfTimeline(now, _selectedTimeline);
    final filteredSales = _sales.where((sale) {
      final saleDate = sale.timestamp.toDate();
      return saleDate.isAfter(startOfTimeline) &&
          saleDate.isBefore(endOfTimeline);
    }).toList();

    setState(() {
      _totalSalesForSelectedTimeline =
          filteredSales.fold(0.0, (sum, sale) => sum + (sale.quantity * _getProductPrice(sale.productId)));
    });
  }

  double _getProductPrice(String productId) {
    final product = _products.firstWhere((product) => product.id == productId, orElse: () => Product(id: '', name: '', stock: 0, price: 0.0, timestamp: Timestamp.now()));
    return product.price;
  }

  void _updateTotalStockForSelectedTimeline() {
    setState(() {
      _totalStockForSelectedTimeline =
          _products.fold(0, (sum, product) => sum + product.stock);
      _currentStockValue = _totalStockForSelectedTimeline.toDouble();
    });
  }

  DateTime _getStartOfTimeline(DateTime now, String timeline) {
    switch (timeline) {
      case 'Monthly':
        return DateTime(now.year, now.month, 1);
      default:
        return now.subtract(Duration(days: now.weekday - 1)); // Weekly
    }
  }

  DateTime _getEndOfTimeline(DateTime now, String timeline) {
    switch (timeline) {
      case 'Monthly':
        return DateTime(now.year, now.month + 1, 1);
      default:
        return now.add(Duration(days: 7 - now.weekday)); // Weekly
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        title: Text('Inventory Summary'),
        backgroundColor: Colors.grey[400],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineSelector(),
              SizedBox(height: 16),
              _buildSalesOverview(),
              SizedBox(height: 16),
              _buildSalesChart(),
              SizedBox(height: 64),
              _buildStockSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[500],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        color: Colors.grey[500],
        elevation: 0,
        margin: EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<String>(
            dropdownColor: Colors.grey[400],
            value: _selectedTimeline,
            items: ['Weekly', 'Monthly'].map((String timeline) {
              return DropdownMenuItem<String>(
                value: timeline,
                child: Text(timeline),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTimeline = value!;
                _updateTotalSalesForSelectedTimeline();
                _updateTotalStockForSelectedTimeline();
              });
            },
            isExpanded: true,
            borderRadius: BorderRadius.circular(8),
            focusColor: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesOverview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        color: Colors.grey[500],
        elevation: 0,
        margin: EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Total Sales for $_selectedTimeline: Kshs ${_totalSalesForSelectedTimeline.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    final salesGroupedByDate = <String, double>{};
    final isMonthly = _selectedTimeline == 'Monthly';
    final now = DateTime.now();

    for (var sale in _sales) {
      final date = isMonthly
          ? DateFormat('MMM').format(sale.timestamp.toDate())
          : DateFormat('EEE').format(sale.timestamp.toDate());

      salesGroupedByDate.update(date, (value) => value + (sale.quantity * _getProductPrice(sale.productId)),
          ifAbsent: () => (sale.quantity * _getProductPrice(sale.productId)));
    }

    final filteredDates = isMonthly
        ? [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ]
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final filteredSalesData = filteredDates.map((date) {
      final salesAmount = salesGroupedByDate[date] ?? 0;
      return BarChartGroupData(
        x: filteredDates.indexOf(date),
        barRods: [
          BarChartRodData(
            toY: salesAmount,
            gradient: getSalesBarGradient(salesAmount),
            width: 60,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 270,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(212, 196, 189, 178),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: isMonthly ? 1000 : 500,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      final date = filteredDates[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          date,
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 0.0, top: 0),
                        child: Text(
                          '${value.toInt()}',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: filteredSalesData,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: EdgeInsets.all(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${filteredDates[group.x.toInt()]}: ${rod.toY.toStringAsFixed(2)}',
                      TextStyle(color: Colors.white),
                    );
                  },
                ),
                touchCallback:
                    (FlTouchEvent event, BarTouchResponse? response) {},
                handleBuiltInTouches: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockSection() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildStockGauge(),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildStockSummary(),
        ),
      ],
    );
  }

  Widget _buildStockGauge() {
    Color _getGaugeColor(double value) {
      if (value < 0.9 * _totalStockForSelectedTimeline) return Colors.red;
      if (value < 1.9 * _totalStockForSelectedTimeline) return Colors.orange;
      else return Colors.green;
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(6.0),
      child: Column(
        children: [
          Expanded(
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: _totalStockForSelectedTimeline.toDouble() +
                      500, // Adjusted maximum
                  ranges: <GaugeRange>[
                    GaugeRange(
                      startValue: 0,
                      endValue: _totalStockForSelectedTimeline.toDouble(),
                      color: _getGaugeColor(_currentStockValue),
                      startWidth: 10,
                      endWidth: 30,
                    ),
                  ],
                  pointers: <GaugePointer>[
                    NeedlePointer(
                      value: _currentStockValue,
                      needleColor: Colors.blue,
                      knobStyle: KnobStyle(
                        borderWidth: 2,
                      ),
                      needleLength: 0.8,
                      animationDuration: 1500,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Container(
                        child: Text(
                          '${_currentStockValue.toStringAsFixed(0)} units',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      angle: 90,
                      positionFactor: 0.3,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 1),
          Slider(
            min: 0,
            max: _totalStockForSelectedTimeline.toDouble() +
                500, // Adjusted maximum
            value: _currentStockValue,
            onChanged: (value) {
              setState(() {
                _currentStockValue = value;
              });
            },
            label: '${_currentStockValue.toStringAsFixed(0)} units',
            activeColor: Colors.blue,
            inactiveColor: Colors.grey[300],
            thumbColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStockSummary() {
    // Find top and lowest stock items
    final topStock = _products.isNotEmpty
        ? _products.reduce((a, b) => a.stock > b.stock ? a : b)
        : Product(
            id: 'default_id',
            name: 'N/A',
            stock: 0,
            price: 0.0,
            timestamp: Timestamp.fromDate(DateTime.now()),
          ); // Default value if no products
    final lowestStock = _products.isNotEmpty
        ? _products.reduce((a, b) => a.stock < b.stock ? a : b)
        : Product(
            id: 'default_id',
            name: 'N/A',
            stock: 0,
            price: 0.0,
            timestamp: Timestamp.fromDate(DateTime.now()),
          ); // Default value if no products

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.5),
            spreadRadius: 4,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        color: Colors.grey[500],
        elevation: 0,
        margin: EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Top Stock: ${topStock.name} - ${topStock.stock} units',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Lowest Stock: ${lowestStock.name} - ${lowestStock.stock} units',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Total Stock: $_totalStockForSelectedTimeline units',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
