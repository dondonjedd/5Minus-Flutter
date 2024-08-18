import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/features/authentication/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utility/network_utility.dart';

class AuthNetworkDatasource {
  const AuthNetworkDatasource();

  Future<UserModel?> signInEmailPassword({required String emailAddress, required String password}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: emailAddress, password: password);
      return await getUserModel();
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Login Error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Login error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<UserModel?> registerEmailPassword({required String emailAddress, required String password}) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
      await sendEmailVerification();
      return await _createUser();
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Register error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Register error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<UserModel?> getUserModel() async {
    try {
      final userCollection = _getUserCollection();
      if (userCollection == null) return null;
      final result = await userCollection.get();
      if (result.data()?.isEmpty ?? true) {
        return _createUser();
      }
      return UserModel.fromMap(result.data());
    } on FirebaseException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Create user error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Create user error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<UserModel?> updateUser(UserModel? usermodel) async {
    try {
      if (usermodel == null) return null;
      final userCollection = _getUserCollection();
      if (userCollection == null) return null;
      await userCollection.set(usermodel.toMap());

      return getUserModel();
    } on FirebaseException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Create user error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Create user error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
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

  Future<UserModel?> signInGoogle() async {
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
      UserCredential user = await FirebaseAuth.instance.signInWithCredential(credential);

      await GoogleSignIn().signOut(); // <-- add this code here
      if (user.additionalUserInfo?.isNewUser ?? false) return await _createUser();
      return await getUserModel();
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Login Error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Logout error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<UserModel?> _createUser() async {
    try {
      final userCollection = _getUserCollection();
      if (userCollection == null) return null;

      await userCollection.set(UserModel.baseUserModel().toMap());
      return UserModel.fromMap((await userCollection.get()).data());
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Create user error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Create user error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  DocumentReference<Map<String, dynamic>>? _getUserCollection() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection("users").doc(uid);
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
