/// Network-address checks shared by authentication and short-lived media URLs.
///
/// Production traffic must use encrypted transports. Plain HTTP/WS remains
/// available only for a server on the same device so local development does
/// not require weakening release traffic.
bool isPermittedHttpUri(Uri uri) {
  if (!uri.hasScheme || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
    return false;
  }
  if (uri.scheme.toLowerCase() == 'https') return true;
  return uri.scheme.toLowerCase() == 'http' &&
      isCanonicalLoopbackHost(uri.host);
}

bool isPermittedWebSocketUri(Uri uri) {
  if (!uri.hasScheme || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
    return false;
  }
  if (uri.scheme.toLowerCase() == 'wss') return true;
  return uri.scheme.toLowerCase() == 'ws' && isCanonicalLoopbackHost(uri.host);
}

bool isCanonicalLoopbackHost(String host) {
  final normalized = host.toLowerCase();
  if (normalized == 'localhost') return true;
  if (normalized == '::1' || normalized == '0:0:0:0:0:0:0:1') {
    return true;
  }
  final octets = normalized.split('.');
  if (octets.length != 4 || octets.first != '127') return false;
  return octets.every((octet) {
    final value = int.tryParse(octet);
    return value != null && value >= 0 && value <= 255;
  });
}
