import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../utility/dialog_utility.dart';

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

  static Future<void> signInEmailPassword(BuildContext context, {required String emailAddress, required String password}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailAddress, password: password);
    } on FirebaseAuthException catch (e) {
      bool res = false;
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        if (e.code == 'user-not-found') log('No user found for that email. Continue with registration');
        if (e.code == 'invalid-credential') log('Invalid Credential');

        if (context.mounted) {
          res = await registerEmailPassword(context, emailAddress: emailAddress, password: password);
        }
      }
      if (!res) {
        if (context.mounted) DialogUtility().showError(context, title: 'Login error', message: 'Invalid Credential');
      }
    } catch (e) {
      if (context.mounted) DialogUtility().showError(context, title: 'Login error', message: 'Invalid Credential');
    }
  }

  static Future<bool> registerEmailPassword(BuildContext context, {required String emailAddress, required String password}) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        log('The password provided is too weak.');
        if (context.mounted) DialogUtility().showError(context, title: 'Login error', message: 'The password provided is too weak.');
      } else if (context.mounted) {
        DialogUtility().showError(context, title: 'Login error', message: 'Invalid Credential');
      }
      return false;
    } catch (e) {
      log(e.toString());
      if (context.mounted) DialogUtility().showError(context, title: 'Login error', message: 'Invalid Credential');
      return false;
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
