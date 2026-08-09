import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

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
      // Firebase Auth is used for sign-in; skip Supabase deep-link auth (app_links).
      authOptions: const FlutterAuthClientOptions(
        detectSessionInUri: false,
      ),
    );
  }
}
