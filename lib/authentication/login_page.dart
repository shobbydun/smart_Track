import 'dart:ui';  // Import this for BackdropFilter and ImageFilter

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_track/components/my_button.dart';
import 'package:smart_track/components/my_textfield.dart';
import 'package:smart_track/components/square_tile.dart';
import 'package:smart_track/database/firestore_services.dart';
import 'package:smart_track/pages/dashboard_page.dart';
import 'package:smart_track/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  LoginPage({
    super.key,
    required this.onTap,
    required this.flutterLocalNotificationsPlugin,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String _errorMessage = "";

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void signUserIn() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.green,
            ),
          );
        },
      );
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      
      final user = userCredential.user;
      
      // Navigate to the Dashboard page
      if (mounted) {
        Navigator.pop(context); // Close the loading dialog
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DashboardPage(
            firestoreServices: FirestoreServices(
              widget.flutterLocalNotificationsPlugin,
              user!.uid,
            ),
          )),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close the loading dialog
        showErrorMessage(e.code);
      }
    }
  }

  void forgotPassword() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[300],
          title: const Text("Reset Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter your email address and we'll send you a link to reset your password."),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "Enter email",
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text;
                if (email.isEmpty) {
                  setState(() {
                    _errorMessage = "Email cannot be empty.";
                    emailController.clear();
                  });
                } else if (!_isValidEmail(email)) {
                  setState(() {
                    _errorMessage = "Invalid email address.";
                    emailController.clear();
                  });
                } else {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    if (mounted) Navigator.of(context).pop(); // Close the dialog
                    if (mounted) showSuccessMessage("Password reset email sent!");
                  } on FirebaseAuthException catch (e) {
                    if (mounted) {
                      setState(() {
                        _errorMessage = e.message ?? "An error occurred";
                      });
                    }
                  }
                }
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  // Helper method to check email validity
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  void showErrorMessage(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 247, 112, 112),
            title: Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      );
    }
  }

  void showSuccessMessage(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.green,
            title: Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/shopKeeper.jpeg',  // Replace with your image path
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 120),
                    const SizedBox(height: 20),
                    Text(
                      "Welcome Back🎉\n    Smart Track",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    MyTextfield(
                      controller: emailController,
                      hintText: "Email",
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),
                    MyTextfield(
                      controller: passwordController,
                      hintText: "Password",
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: forgotPassword,
                            child: Text(
                              "Forgot password?",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    MyButton(
                      text: "Sign in",
                      onTap: signUserIn,
                    ),
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.grey[400],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Or continue with, ",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.grey[400],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SquareTile(
                          imagePath: 'assets/google.png',
                          onTap: () => AuthService().signInWithGoogle(),
                        ),
                        const SizedBox(width: 25),
                      ],
                    ),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Not a member?",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            "Register now",
                            style: TextStyle(
                                color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
