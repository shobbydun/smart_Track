import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_track/components/notification_model.dart';

class SaleWithProduct {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final Timestamp timestamp;

  SaleWithProduct({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.timestamp,
  });
}

class Product {
  final String id;
  final String name;
  final int stock;
  final double price;
  final Timestamp timestamp;

  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    required this.timestamp,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return Product(
      id: doc.id,
      name: data?['name'] ?? 'Unknown',
      stock: data?['stock'] ?? 0,
      price: (data?['price'] as num?)?.toDouble() ?? 0.0,
      timestamp: data?['timestamp'] ?? Timestamp.now(),
    );
  }
}

class Sale {
  final String id;
  final String productId;
  final int quantity;
  final String? productName;
  final double price;
  final Timestamp timestamp;

  Sale({
    required this.id,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.price,
    required this.timestamp,
  });

  DateTime get timestampAsDateTime => timestamp.toDate();

  factory Sale.fromFirestore(Map<String, dynamic> firestore, String id) {
    return Sale(
      id: id,
      productId: firestore['productId'] ?? '',
      quantity: firestore['quantity'] ?? 0,
      productName: firestore['productName'],
      price: (firestore['price'] as num?)?.toDouble() ?? 0.0,
      timestamp: firestore['timestamp'] ?? Timestamp.now(),
    );
  }
}

class FirestoreServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final String userId;

  FirestoreServices(this._flutterLocalNotificationsPlugin, this.userId);

  String get _userCollection => 'users/$userId';

  Future<String?> getBusinessName() async {
    try {
      if (userId.isEmpty) {
        print("User ID is empty.");
        return 'No Business Name';
      }

      final docSnapshot = await _db.collection('users').doc(userId).get();
      if (!docSnapshot.exists) {
        print("Document does not exist for userId: $userId");
        return 'No Business Name';
      }

      final data = docSnapshot.data();
      if (data == null || !data.containsKey('businessName')) {
        print("Document does not contain 'businessName' field.");
        return 'No Business Name';
      }

      return data['businessName'] as String? ?? 'N/A';
    } catch (e) {
      print("Error fetching business name: $e");
      return null;
    }
  }

  Future<void> addSale(String productId, int quantity) async {
    try {
      await _db.runTransaction((transaction) async {
        final productRef = _db.collection('$_userCollection/products').doc(productId);
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception('Product not found');
        }

        final currentStock = productSnapshot.data()?['stock'] ?? 0;

        if (currentStock < quantity) {
          throw Exception('Not enough stock available');
        }

        final price = (productSnapshot.data()?['price'] as num?)?.toDouble() ?? 0.0;
        final saleRef = _db.collection('$_userCollection/sales').doc();
        final saleData = {
          'productId': productId,
          'quantity': quantity,
          'price': price,
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Add sale
        transaction.set(saleRef, saleData);

        // Update product stock
        transaction.update(productRef, {'stock': currentStock - quantity});
      });
    } catch (e) {
      print("Error adding sale for user $userId: $e");
    }
  }

  Future<Sale?> getSaleById(String saleId) async {
    try {
      final saleDoc = await _db.collection('$_userCollection/sales').doc(saleId).get();
      if (saleDoc.exists) {
        return Sale.fromFirestore(saleDoc.data()!, saleDoc.id);
      } else {
        print("Sale not found for ID: $saleId");
        return null;
      }
    } catch (e) {
      print("Error fetching sale by ID: $e");
      return null;
    }
  }

  Future<void> updateSale(String saleId, String productId, int quantity) async {
    try {
      final saleRef = _db.collection('$_userCollection/sales').doc(saleId);
      await saleRef.update({
        'productId': productId,
        'quantity': quantity,
        'timestamp': FieldValue.serverTimestamp(), // Optionally update timestamp
      });
    } catch (e) {
      print("Error updating sale: $e");
    }
  }

  Future<void> deleteSale(String saleId) async {
    try {
      await _db.runTransaction((transaction) async {
        final saleRef = _db.collection('$_userCollection/sales').doc(saleId);
        final saleSnapshot = await transaction.get(saleRef);

        if (!saleSnapshot.exists) {
          throw Exception('Sale not found');
        }

        final saleData = saleSnapshot.data()!;
        final productId = saleData['productId'] ?? '';
        final quantity = saleData['quantity'] ?? 0;

        final productRef = _db.collection('$_userCollection/products').doc(productId);
        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception('Product not found');
        }

        final currentStock = productSnapshot.data()?['stock'] ?? 0;

        // Delete sale
        transaction.delete(saleRef);

        // Update product stock
        transaction.update(productRef, {'stock': currentStock + quantity});
      });
    } catch (e) {
      print("Error deleting sale for user $userId: $e");
    }
  }

  Stream<List<Sale>> getSales() {
    return _db
        .collection('$_userCollection/sales')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final sales = snapshot.docs
              .map((doc) => Sale.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          return sales;
        });
  }

  Stream<List<Sale>> getSalesByDate(DateTime startOfDay, DateTime endOfDay) {
    return _db
        .collection('$_userCollection/sales')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final sales = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Sale.fromFirestore(data, doc.id);
          }).toList();
          return sales;
        });
  }

  Stream<double> getTotalSalesByDate(DateTime startOfDay, DateTime endOfDay) {
    return getSalesByDate(startOfDay, endOfDay).map((sales) {
      double total = 0.0;
      for (var sale in sales) {
        total += sale.price * sale.quantity;
      }
      return total;
    });
  }

  Future<void> addProduct(String name, int stock, double price) async {
    try {
      await _db.collection('$_userCollection/products').add({
        'name': name,
        'stock': stock,
        'price': price,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding product for user $userId: $e");
    }
  }

  Future<void> updateProduct(String id, String name, int stock, double price) async {
    try {
      await _db.collection('$_userCollection/products').doc(id).update({
        'name': name,
        'stock': stock,
        'price': price,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating product for user $userId: $e");
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _db.collection('$_userCollection/products').doc(id).delete();
    } catch (e) {
      print("Error deleting product for user $userId: $e");
    }
  }

  Stream<List<Product>> getProducts() {
    return _db
        .collection('$_userCollection/products')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
          return products;
        });
  }

  Future<String?> getProductNameById(String productId) async {
    try {
      final productRef = _db.collection('$_userCollection/products').doc(productId);
      final productSnapshot = await productRef.get();

      if (!productSnapshot.exists) {
        print("Product not found for ID: $productId");
        return null;
      }

      final productData = productSnapshot.data();
      return productData?['name'] as String?;
    } catch (e) {
      print("Error fetching product name for productId $productId: $e");
      return null;
    }
  }

  Future<void> addFeedback(String feedback) async {
    try {
      await _db.collection('$_userCollection/feedback').add({
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding feedback for user $userId: $e");
    }
  }

  Future<void> checkLowStockAndNotify() async {
    try {
      final products = await _db.collection('$_userCollection/products').get();
      bool hasLowStock = false;

      for (var doc in products.docs) {
        final data = doc.data();
        final stock = data['stock'] as int;
        if (stock < 10) {
          hasLowStock = true;
          await _flutterLocalNotificationsPlugin.show(
            2,
            'Low Stock Alert',
            'Product ${data['name']} is low on stock!',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'channel_id',
                'channel_name',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
              ),
            ),
          );
          await _db.collection('$_userCollection/notifications').add({
            'title': 'Low Stock Alert',
            'body': 'Product ${data['name']} is low on stock!',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      if (!hasLowStock) {
        await _flutterLocalNotificationsPlugin.show(
          3,
          'Stock Check',
          'All products have sufficient stock.',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'channel_name',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
            ),
          ),
        );
        await _db.collection('$_userCollection/notifications').add({
          'title': 'Stock Check',
          'body': 'All products have sufficient stock.',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error checking low stock for user $userId: $e");
    }
  }

  Stream<List<NotificationModel>> getNotifications() {
    return _db
        .collection('$_userCollection/notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          return notifications;
        });
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _db.collection('$_userCollection/notifications').doc(id).delete();
    } catch (e) {
      print("Error deleting notification for user $userId: $e");
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      final batch = _db.batch();
      final notifications = await _db.collection('$_userCollection/notifications').get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print("Error deleting all notifications for user $userId: $e");
    }
  }
}
