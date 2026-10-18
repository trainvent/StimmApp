/// Accepts public website/social URLs without credentials or executable schemes.
Uri? parseWebsiteLink(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final text = value.trim();
  if (text.length > 2048 || RegExp(r'\s').hasMatch(text)) return null;
  final uri = Uri.tryParse(text);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      !uri.host.contains('.') ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}
