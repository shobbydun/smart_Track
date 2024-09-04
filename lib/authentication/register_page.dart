import 'dart:ui'; // Import this for BackdropFilter and ImageFilter

import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_track/components/my_button.dart';
import 'package:smart_track/components/my_textfield.dart';
import 'package:smart_track/components/square_tile.dart';
import 'package:smart_track/database/firestore_services.dart';
import 'package:smart_track/pages/dashboard_page.dart';
import 'package:smart_track/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  RegisterPage({
    super.key,
    required this.onTap,
    required this.flutterLocalNotificationsPlugin,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final businessNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    businessNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void signUserUp() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (passwordController.text == confirmPasswordController.text) {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        String userId = userCredential.user?.uid ?? '';
        if (userId.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(userId).set(
              {
                'email': emailController.text,
                'businessName': businessNameController.text,
              },
              SetOptions(
                  merge:
                      true)); // Using merge to avoid overwriting existing data
        }

        // Navigate to the Dashboard page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => DashboardPage(
                    firestoreServices: FirestoreServices(
                      widget.flutterLocalNotificationsPlugin,
                      userId,
                    ),
                  )),
        );
      } else {
        showErrorMessage("Passwords don't match❌");
      }
    } on FirebaseAuthException catch (e) {
      showErrorMessage(e.message ?? 'An error occurred');
    } on FirebaseException catch (e) {
      showErrorMessage('Firestore error: ${e.message}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/dreadKeeper.jpeg',
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
                    const SizedBox(height: 90),
                    Text(
                      "W E L C O M E",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 35),

                    // Business Name TextField
                    MyTextfield(
                      controller: businessNameController,
                      hintText: "Business Name",
                      obscureText: false,
                    ),
                    const SizedBox(height: 10),
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
                    MyTextfield(
                      controller: confirmPasswordController,
                      hintText: "Confirm Password",
                      obscureText: true,
                    ),
                    const SizedBox(height: 25),
                    MyButton(
                      text: "Sign up",
                      onTap: signUserUp,
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
                        //keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android
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
                          "Already have an account?",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: const Text(
                            "Login now",
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }
}
