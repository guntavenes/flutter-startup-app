class SharedMember {
  final String uid;
  final String? email;
  final String? displayName;
  final String role;
  final int joinedAtMs;

  const SharedMember({
    required this.uid,
    this.email,
    this.displayName,
    required this.role,
    this.joinedAtMs = 0,
  });
}
