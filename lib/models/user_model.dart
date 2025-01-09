class UserModel {
  final String uid;
  final String username;
  final String phoneNumber;
  final String email;

  UserModel({
    required this.uid,
    required this.username,
    required this.phoneNumber,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'phone_number': phoneNumber,
      'email': email,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      email: map['email'] ?? '',
    );
  }
}
