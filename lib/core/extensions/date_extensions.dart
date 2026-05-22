extension DateFormatExtension on int? {
  String toShortDateText() {
    if (this == null) {
      return '-';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(this!);

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day.$month.$year';
  }
}
