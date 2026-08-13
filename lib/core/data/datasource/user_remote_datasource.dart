import 'package:five_minus/core/service/supabase_service.dart';

class UserRemoteDatasource {
  const UserRemoteDatasource();

  Future<Map<String, dynamic>?> fetchUser(String id) => SupabaseService.fetchUser(id);

  Future<void> upsertUser(Map<String, dynamic> row) => SupabaseService.upsertUser(row);
}
