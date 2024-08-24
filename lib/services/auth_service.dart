import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Google sign in
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      // Check if the user is null (sign-in was canceled or failed)
      if (gUser == null) {
        // User canceled the sign-in process or it failed
        print('Google sign-in was canceled or failed.');
        return null;
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Check if authentication tokens are null
      if (gAuth.accessToken == null || gAuth.idToken == null) {
        print('Google authentication tokens are null.');
        return null;
      }

      // Create a new credential for the user
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // Sign in to Firebase with the credential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      // Handle and log the error
      print('Error signing in with Google: $e');
      return null;
    }
  }
}
