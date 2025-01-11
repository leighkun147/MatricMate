class UserModel {
  final String uid;
  final String username;
  final String phoneNumber;
  final String email;
  final int coins;
  final int ranking;
  final bool activation;
  final int referralEarnings;
  final int referralCount;

  UserModel({
    required this.uid,
    required this.username,
    required this.phoneNumber,
    required this.email,
    this.coins = 0,
    this.ranking = 0,
    this.activation = false,
    this.referralEarnings = 0,
    this.referralCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'phone_number': phoneNumber,
      'email': email,
      'coins': coins,
      'ranking': ranking,
      'activation': activation,
      'referral_earnings': referralEarnings,
      'referral_count': referralCount,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      username: map['username'] as String,
      phoneNumber: map['phone_number'] as String,
      email: map['email'] as String,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      ranking: (map['ranking'] as num?)?.toInt() ?? 0,
      activation: map['activation'] as bool? ?? false,
      referralEarnings: (map['referral_earnings'] as num?)?.toInt() ?? 0,
      referralCount: (map['referral_count'] as num?)?.toInt() ?? 0,
    );
  }
}
