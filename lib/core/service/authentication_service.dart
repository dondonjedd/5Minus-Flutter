import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthenticationService {
  static Future<bool> signInGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      await FirebaseAuth.instance.signInWithCredential(credential);

      await GoogleSignIn().signOut(); // <-- add this code here
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> signInEmailPassword({required String emailAddress, required String password}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailAddress, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        if (e.code == 'user-not-found') log('No user found for that email. Continue with registration');
        if (e.code == 'invalid-credential') log('Invalid Credential');

        registerEmailPassword(emailAddress: emailAddress, password: password);
      } else if (e.code == 'wrong-password') {
        log('Wrong password provided for that user.');
      }
      return false;
    }
  }

  static void registerEmailPassword({required String emailAddress, required String password}) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        log('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        log('The account already exists for that email.');
      }
    } catch (e) {
      log(e.toString());
    }
  }

  static void signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      log(e.toString());
    }
  }

  static Future<String> apple() async {
    final response = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    return response.identityToken ?? '';
  }

  static Future<String> facebook() async {
    final response = await FacebookAuth.instance.login();
    return response.accessToken?.tokenString ?? '';
  }

  const AuthenticationService._();
}
