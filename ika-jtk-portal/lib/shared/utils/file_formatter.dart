String formatFileName(String? url) {
  if (url == null || url.isEmpty) return '';
  final lastPart = url.split('/').last;
  if (lastPart.contains('___')) {
    return lastPart.split('___').last;
  }
  return lastPart;
}
