/// Trims a server address and adds http when the scheme was left off.
String normalizeServerUrl(String raw) {
  var url = raw.trim();
  if (url.isEmpty) {
    return '';
  }
  if (!url.contains('://')) {
    url = 'http://$url';
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}
