import 'dart:convert';

class UserModel {
  String? username;
  int? wins;
  int? loss;
  int? rank;
  int? points;

  UserModel({this.username, this.wins, this.loss, this.rank, this.points});

  static UserModel baseUserModel() {
    return UserModel(username: '', wins: 0, loss: 0, rank: -1, points: 0);
  }

  factory UserModel.fromMap(Map<String, dynamic>? data) => UserModel(
        username: data?['username'] as String?,
        wins: data?['wins'] as int?,
        loss: data?['loss'] as int?,
        rank: data?['rank'] as int?,
        points: data?['points'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'username': username,
        'wins': wins,
        'loss': loss,
        'rank': rank,
        'points': points,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [UserModel].
  factory UserModel.fromJson(String data) {
    return UserModel.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [UserModel] to a JSON string.
  String toJson() => json.encode(toMap());

  UserModel copyWith({
    String? username,
    int? wins,
    int? loss,
    int? rank,
    int? points,
  }) {
    return UserModel(
      username: username ?? this.username,
      wins: wins ?? this.wins,
      loss: loss ?? this.loss,
      rank: rank ?? this.rank,
      points: points ?? this.points,
    );
  }
}
