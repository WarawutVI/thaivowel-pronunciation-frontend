class UserProfile {
  final String username;

  const UserProfile({required this.username});

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        username: j['username'] as String,
      );
}
