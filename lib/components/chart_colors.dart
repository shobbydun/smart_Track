import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_track/database/firestore_services.dart';

/// Creates a gradient for sales bars based on the amount.
LinearGradient getSalesBarGradient(double salesAmount) {
  if (salesAmount > 5000) {
    return LinearGradient(
      colors: [
        Colors.green.shade500,
        Colors.blue.shade300,
      ],
      transform: const GradientRotation(pi / 9),
    ); // High sales amount
  } else if (salesAmount > 2000) {
    return LinearGradient(
      colors: [
        Colors.yellow.shade800,
        Colors.purple,
      ],
      transform: const GradientRotation(pi / 9),
    ); // Medium sales amount
  } else {
    return LinearGradient(
      colors: [
        Colors.red.shade800,
        Colors.brown,
      ],
      transform: const GradientRotation(pi / 9),
    ); // Low sales amount
  }
}

/// Creates a gradient for stock bars based on the amount.
LinearGradient getStockBarGradient(int stockAmount) {
  if (stockAmount > 100) {
    return LinearGradient(
      colors: [
        Colors.blue.shade800,
        Colors.brown.shade300,
      ],
      transform: const GradientRotation(pi / 10),
    ); // High stock amount
  } else if (stockAmount > 50) {
    return LinearGradient(
      colors: [
        Colors.purple.shade800,
        Colors.purple.shade300,
      ],
      transform: const GradientRotation(pi / 40),
    ); // Medium stock amount
  } else {
    return LinearGradient(
      colors: [
        Colors.red.shade800,
        Colors.red.shade300,
      ],
      transform: const GradientRotation(pi / 40),
    ); // Low stock amount
  }
}

/// Generates bar chart data for sales.
BarChartData getSalesBarChartData(List<Sale> sales, String selectedTimeline) {
  final salesGroupedByDate = <String, double>{};
  final isMonthly = selectedTimeline == 'Monthly';
  final now = DateTime.now();

  // Group sales by date or month depending on the timeline
  for (var sale in sales) {
    final date = isMonthly
        ? DateFormat('MMM').format(sale.timestamp.toDate())
        : DateFormat('EEE').format(sale.timestamp.toDate());
    salesGroupedByDate.update(date, (value) => value + sale.price,
        ifAbsent: () => sale.price);
  }

  final filteredDates = isMonthly
      ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final filteredSalesData = filteredDates.map((date) {
    final salesAmount = salesGroupedByDate[date] ?? 0;
    return BarChartGroupData(
      x: filteredDates.indexOf(date),
      barRods: [
        BarChartRodData(
          toY: salesAmount,
          gradient: getSalesBarGradient(salesAmount), // Use gradient here
          width: 30, // Thicker bars
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }).toList();

  return BarChartData(
    titlesData: FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            final date = filteredDates[value.toInt()];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: RotatedBox(
                quarterTurns: 1,
                child: Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            );
          },
        ),
      ),
    ),
    borderData: FlBorderData(
      show: false, // Removed border to match the desired look
    ),
    gridData: FlGridData(show: false),
    barGroups: filteredSalesData,
  );
}

/// Generates bar chart data for stock.
BarChartData getStockBarChartData(List<Product> products) {
  final stockGroupedByProduct = <String, int>{};

  // Group stock by product name
  for (var product in products) {
    stockGroupedByProduct.update(product.name, (value) => value + product.stock,
        ifAbsent: () => product.stock);
  }

  final filteredProductNames = stockGroupedByProduct.keys.toList();

  final filteredStockData = filteredProductNames.map((productName) {
    final stockAmount = stockGroupedByProduct[productName]!;
    return BarChartGroupData(
      x: filteredProductNames.indexOf(productName),
      barRods: [
        BarChartRodData(
          toY: stockAmount.toDouble(),
          gradient: getStockBarGradient(stockAmount), // Use gradient here
          width: 30, // Thicker bars
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }).toList();

  return BarChartData(
    titlesData: FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            final productName = filteredProductNames[value.toInt()];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: RotatedBox(
                quarterTurns: 1,
                child: Text(
                  productName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            );
          },
        ),
      ),
    ),
    borderData: FlBorderData(
      show: false, // Removed border to match the desired look
    ),
    gridData: FlGridData(show: false),
    barGroups: filteredStockData,
  );
}
