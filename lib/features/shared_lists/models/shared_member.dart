class SharedMember {
  final String uid;
  final String? email;
  final String? displayName;
  final String role;

  const SharedMember({
    required this.uid,
    this.email,
    this.displayName,
    required this.role,
  });
}
