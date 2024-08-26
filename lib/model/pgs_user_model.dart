import 'dart:convert';

class PgsUserModel {
  String? id;
  String? username;
  int? points;
  String? icon;

  PgsUserModel({this.id, this.username, this.points, this.icon});

  factory PgsUserModel.fromMap(Map<String, dynamic> data) => PgsUserModel(
        id: data['Id'] as String?,
        username: data['username'] as String?,
        points: data['points'] as int?,
        icon: data['icon'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'Id': id,
        'username': username,
        'points': points,
        'icon': icon,
      };

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [PgsUserModel].
  factory PgsUserModel.fromJson(String data) {
    return PgsUserModel.fromMap(json.decode(data) as Map<String, dynamic>);
  }

  /// `dart:convert`
  ///
  /// Converts [PgsUserModel] to a JSON string.
  String toJson() => json.encode(toMap());

  PgsUserModel copyWith({
    String? id,
    String? username,
    int? points,
    String? icon,
  }) {
    return PgsUserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      points: points ?? this.points,
      icon: icon ?? this.icon,
    );
  }
}
