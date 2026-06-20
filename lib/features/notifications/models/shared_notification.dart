class SharedNotification {
  final String id;
  final String type;
  final String message;
  final String createdBy;
  final int createdAt;

  const SharedNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.createdBy,
    required this.createdAt,
  });
}
