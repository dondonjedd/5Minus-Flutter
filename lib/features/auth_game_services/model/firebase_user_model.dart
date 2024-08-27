import 'dart:convert';

class FirebaseUserModel {
  String playerId;
  String username;
  int? wins = 0;
  int? loss = 0;
  int? points = 0;
  String? icon;

  FirebaseUserModel({
    required this.playerId,
    required this.username,
    this.wins = 0,
    this.loss = 0,
    this.points = 0,
    this.icon,
  });

  factory FirebaseUserModel.fromMap(Map<String, dynamic> data) {
    return FirebaseUserModel(
      playerId: (data['playerId'] as String?) ?? '-',
      username: (data['username'] as String?) ?? '-',
      wins: data['wins'] as int?,
      loss: data['loss'] as int?,
      points: data['points'] as int?,
      icon: data['icon'] as String?,
    );
  }

  static FirebaseUserModel baseUserModel() {
    return FirebaseUserModel(playerId: '', username: '', wins: 0, loss: 0, points: 0, icon: '');
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'username': username,
        'wins': wins,
        'loss': loss,
        'points': points,
        'icon': icon,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [FirebaseUserModel].
  factory FirebaseUserModel.fromJson(String data) {
    return FirebaseUserModel.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [FirebaseUserModel] to a JSON string.
  String toJson() => json.encode(toMap());

  FirebaseUserModel copyWith({
    String? playerId,
    String? username,
    int? wins,
    int? loss,
    int? points,
    String? icon,
  }) {
    return FirebaseUserModel(
      playerId: playerId ?? this.playerId,
      username: username ?? this.username,
      wins: wins ?? this.wins,
      loss: loss ?? this.loss,
      points: points ?? this.points,
      icon: icon ?? this.icon,
    );
  }
}
