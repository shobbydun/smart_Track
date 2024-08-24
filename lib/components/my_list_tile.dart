import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyListTile extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final Timestamp timestamp;
  final void Function(String, String, double, int) onEdit; // Updated callback to include quantity
  final void Function(String) onDelete;
  final int quantity; // Added quantity
  final Text title; // Added title

  const MyListTile({
    Key? key,
    required this.id,
    required this.name,
    required this.price,
    required this.timestamp,
    required this.onEdit,
    required this.onDelete,
    required this.quantity, // Added quantity
    required this.title, // Added title
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = timestamp.toDate();
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            spreadRadius: 3,
            blurRadius: 3,
            offset: Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(10.0),
        title: title,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Quantity: $quantity'), // Display quantity
            Text('Kshs ${price.toStringAsFixed(2)}'),
            SizedBox(height: 4.0),
            Text(
              'Date: $formattedDate',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              onEdit(id, name, price, quantity); // Trigger the edit callback
            } else if (value == 'delete') {
              onDelete(id); // Trigger the delete callback
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8.0),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8.0),
                    Text('Delete'),
                  ],
                ),
              ),
            ];
          },
          color: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
