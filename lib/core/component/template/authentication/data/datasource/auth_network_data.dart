import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/core/component/template/authentication/model/user_model.dart';
import 'package:five_minus/core/service/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../../errors/exceptions.dart';
import '../../../../../utility/network_utility.dart';

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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      final data = await SupabaseService.fetchUser(uid);
      if (data == null) {
        return _createUser();
      }
      return UserModel.fromMap(data);
    } catch (e) {
      throw const ServerException(title: 'Create user error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
    }
  }

  Future<UserModel?> updateUser(UserModel? usermodel) async {
    try {
      if (usermodel == null) return null;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      await SupabaseService.upsertUser({
        'id': uid,
        'player_id': uid,
        ...usermodel.toSupabaseMap(),
      });

      return getUserModel();
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
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential user = await FirebaseAuth.instance.signInWithCredential(credential);

      await GoogleSignIn().signOut();
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final base = UserModel.baseUserModel();
      await SupabaseService.upsertUser({
        'id': uid,
        'player_id': uid,
        ...base.toSupabaseMap(),
      });
      final data = await SupabaseService.fetchUser(uid);
      return UserModel.fromMap(data);
    } on FirebaseAuthException catch (e) {
      throw ServerException(title: e.code, message: e.message ?? 'Create user error', statusCode: '999', type: '2');
    } catch (e) {
      throw const ServerException(title: 'Create user error', message: 'Something unexpected happenned', statusCode: '999', type: '2');
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
