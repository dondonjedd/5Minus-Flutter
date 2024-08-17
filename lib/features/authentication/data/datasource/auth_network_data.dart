import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utility/network_utility.dart';

class AuthNetworkDatasource {
  const AuthNetworkDatasource();

  Future<bool> signInEmailPassword({required String emailAddress, required String password}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailAddress, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Login Error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Login error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<bool> registerEmailPassword({required String emailAddress, required String password}) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
      return await sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Login Error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Login error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<bool> sendEmailVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

      return true;
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Login Error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Login error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<bool> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Login Error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Logout error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<bool> signInGoogle() async {
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
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Login Error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Logout error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<bool> networkCall({
    required final String param,
    required final String token,
    required final String sessionId,
    required final String hostAddress,
  }) async {
    try {
      final response = await NetworkUtility.post(
          url: '$hostAddress/blablabla',
          body: {
            'body1': param,
          },
          authenticationToken: token,
          sessionId: sessionId);
      if (response.isResponseSuccess) {
        return true;
      }
      throw ServerException(
          title: response.responseError.title,
          message: response.responseError.message,
          statusCode: response.statusCode.toString(),
          type: response.responseError.type);
    } on ServerException {
      rethrow;
    } catch (e, s) {
      debugPrintStack(stackTrace: s);
      throw ServerException(
        message: e.toString(),
        statusCode: '505',
      );
    }
  }
}
