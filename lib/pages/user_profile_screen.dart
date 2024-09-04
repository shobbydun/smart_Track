import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_track/database/firestore_services.dart';

class UserProfileScreen extends StatefulWidget {
  final FirestoreServices firestoreServices;

  const UserProfileScreen({Key? key, required this.firestoreServices})
      : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? businessName;
  String? email;
  int stock = 0;
  double totalSales = 0.0;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _fetchUserProfile();
      _fetchBusinessData();
    } else {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          businessName = docSnapshot.get('businessName') ?? 'N/A';
          email = docSnapshot.get('email') ?? 'N/A';
        });
      } else {
        setState(() {
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
      print("Error fetching user profile: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

Future<void> _fetchBusinessData() async {
  setState(() {
    isLoading = true;
    hasError = false;
  });

  try {
    if (user == null) {
      throw Exception("No user logged in");
    }

    final userId = user!.uid;

    // Fetch products related to the user
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('products')
        .get();

    // Calculate total stock
    int totalStock = productsSnapshot.docs.fold<int>(0, (sum, doc) {
      final productStock = (doc.get('stock') ?? 0) as int;
      return sum + productStock;
    });

    // Define the time range for today
    final now = DateTime.now().toUtc();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0).toUtc();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toUtc();

    print("Start of Day (UTC): $startOfDay");
    print("End of Day (UTC): $endOfDay");

    // Fetch sales for today related to the user
    final salesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    print("Sales Query Snapshot: ${salesSnapshot.docs.length} documents found");

    // Calculate total sales
    double totalSalesAmount = 0.0;
    for (var doc in salesSnapshot.docs) {
      final price = (doc.get('price') as num?)?.toDouble() ?? 0.0;
      print("Document ID: ${doc.id}, Price: $price");
      totalSalesAmount += price;
    }

    print("Total Stock: $totalStock");
    print("Total Sales Amount: $totalSalesAmount");

    setState(() {
      stock = totalStock;
      totalSales = totalSalesAmount;
    });
  } catch (e) {
    setState(() {
      hasError = true;
    });
    print("Error fetching business data: $e");
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  Future<void> _changePassword() async {
    bool? shouldChange = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: Text('Are you sure you want to change your password?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (shouldChange == true) {
      Navigator.pushNamed(context, '/login_register_page');
    }
  }

  Future<void> _logout() async {
    bool shouldLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login_register_page');
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[300],
          title: Text('Request Help'),
          content: Text(
              'Please contact our support team at shobbyduncan@gmail.com or call us at 0710285209 for assistance.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[300],
          title: Text(
            'Send Feedback',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We value your feedback! Please share your thoughts or report any issues.',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              SizedBox(height: 10),
              TextField(
                controller: feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your feedback here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final feedback = feedbackController.text.trim();
                if (feedback.isNotEmpty) {
                  try {
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('feedback')
                          .add({
                        'userId': user!.uid,
                        'feedback': feedback,
                        'timestamp': Timestamp.now(),
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Feedback successfully sent')),
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User is not authenticated')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sending feedback: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Feedback cannot be empty')),
                  );
                }
              },
              child: Text(
                'Send',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        title: Text(
          'User Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(child: Text('Failed to load data'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.green[500],
                          child: Icon(Icons.person, size: 60, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          businessName?.toUpperCase() ?? 'Loading...',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          email ?? 'Loading...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Business Overview:',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Current Stock: $stock items',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      // Text(
                      //   'Total Sales today: Kshs ${totalSales.toStringAsFixed(2)}',
                      //   style: GoogleFonts.poppins(
                      //     fontSize: 16,
                      //     color: Colors.grey[700],
                      //   ),
                      // ),
                      SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[500],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          ),
                          child: Text(
                            'Change Password',
                            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: _showHelpDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                              ),
                              child: Text(
                                'Request Help',
                                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _showFeedbackDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                              ),
                              child: Text(
                                'Send Feedback',
                                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
