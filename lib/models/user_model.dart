class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? avatar;
  final String? about;
  final String? lastSeen;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.avatar,
    this.about,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      avatar: json['avatar'],
      about: json['about'],
      lastSeen: json['last_seen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'avatar': avatar,
      'about': about,
      'last_seen': lastSeen,
    };
  }
}
