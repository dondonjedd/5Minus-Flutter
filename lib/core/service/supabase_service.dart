import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:five_minus/core/errors/exceptions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env. '
        'Copy .env.example to .env and fill in your project values.',
      );
    }

    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
      // Firebase JWT is the identity seam; skip Supabase Auth session recovery.
      accessToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
        return user.getIdToken();
      },
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: false,
      ),
    );
  }

  static Future<Map<String, dynamic>?> fetchMatch(String gameCode) async {
    try {
      final data = await _client.from('matches').select().eq('game_code', gameCode).maybeSingle();
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        title: 'Match fetch error',
        message: e.toString(),
        statusCode: '999',
      );
    }
  }

  static Future<bool> matchExists(String gameCode) async {
    try {
      final res = await _client.from('matches').select('game_code').eq('game_code', gameCode).maybeSingle();
      return res != null;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        title: 'Match exists error',
        message: e.toString(),
        statusCode: '999',
      );
    }
  }

  static Future<Map<String, dynamic>> rpcMatchPlay(
    String functionName,
    Map<String, dynamic> params,
  ) async {
    try {
      final data = params.isEmpty
          ? await _client.rpc(functionName)
          : await _client.rpc(functionName, params: params);
      if (data == null) return <String, dynamic>{};
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      if (data is String) {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
      throw const ServerException(
        title: 'Match play error',
        message: 'Unexpected rpc payload',
        statusCode: '999',
      );
    } on PostgrestException catch (e) {
      throw ServerException(
        title: 'Match play error',
        message: e.message,
        statusCode: e.code ?? '999',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        title: 'Match play error',
        message: e.toString(),
        statusCode: '999',
      );
    }
  }

  static Future<void> _syncRealtimeAuth() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    await _client.realtime.setAuth(token);
  }

  /// Emits the latest match row map, or `null` when the row is deleted.
  /// Cancel the subscription to unsubscribe the underlying Realtime channel.
  static Stream<Map<String, dynamic>?> watchMatch(String gameCode) {
    late final StreamController<Map<String, dynamic>?> controller;
    RealtimeChannel? channel;

    controller = StreamController<Map<String, dynamic>?>(
      onListen: () {
        () async {
          try {
            await _syncRealtimeAuth();
            if (controller.isClosed) return;
            channel = _client.channel('match:$gameCode').onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'matches',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'game_code',
                value: gameCode,
              ),
              callback: (payload) {
                if (controller.isClosed) return;
                if (payload.eventType == PostgresChangeEvent.delete) {
                  controller.add(null);
                  return;
                }
                controller.add(Map<String, dynamic>.from(payload.newRecord));
              },
            ).subscribe();
          } catch (e) {
            if (controller.isClosed) return;
            controller.addError(
              ServerException(
                title: 'Match watch error',
                message: e.toString(),
                statusCode: '999',
              ),
            );
          }
        }();
      },
      onCancel: () async {
        await channel?.unsubscribe();
        channel = null;
      },
    );

    return controller.stream;
  }

  static Future<List<Map<String, dynamic>>> fetchSeats(String gameCode) async {
    try {
      final rows = await _client.from('match_players').select().eq('game_code', gameCode).order('seat');
      return rows.map((e) => Map<String, dynamic>.from(e)).toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        title: 'Seat fetch error',
        message: e.toString(),
        statusCode: '999',
      );
    }
  }

  static Future<void> updateSeat(String gameCode, String userId, Map<String, dynamic> patch) async {
    try {
      await _client.from('match_players').update(patch).eq('game_code', gameCode).eq('user_id', userId);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        title: 'Seat update error',
        message: e.toString(),
        statusCode: '999',
      );
    }
  }

  /// Emits on any Seat change for this Match. Payload is the new row, or `null` on delete.
  static Stream<Map<String, dynamic>?> watchSeats(String gameCode) {
    late final StreamController<Map<String, dynamic>?> controller;
    RealtimeChannel? channel;

    controller = StreamController<Map<String, dynamic>?>(
      onListen: () {
        () async {
          try {
            await _syncRealtimeAuth();
            if (controller.isClosed) return;
            channel = _client.channel('match_players:$gameCode').onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'match_players',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'game_code',
                value: gameCode,
              ),
              callback: (payload) {
                if (controller.isClosed) return;
                if (payload.eventType == PostgresChangeEvent.delete) {
                  controller.add(null);
                  return;
                }
                controller.add(Map<String, dynamic>.from(payload.newRecord));
              },
            ).subscribe();
          } catch (e) {
            if (controller.isClosed) return;
            controller.addError(
              ServerException(
                title: 'Seat watch error',
                message: e.toString(),
                statusCode: '999',
              ),
            );
          }
        }();
      },
      onCancel: () async {
        await channel?.unsubscribe();
        channel = null;
      },
    );

    return controller.stream;
  }

  static Future<Map<String, dynamic>?> fetchUser(String id) async {
    try {
      final data = await _client.from('users').select().eq('id', id).maybeSingle();
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        title: 'User fetch error',
        message: e.toString(),
        statusCode: '999',
      );
    }
  }

  static Future<void> upsertUser(Map<String, dynamic> row) async {
    try {
      await _client.from('users').upsert(row, onConflict: 'id');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        title: 'User upsert error',
        message: e.toString(),
        statusCode: '999',
      );
    }
  }
}
