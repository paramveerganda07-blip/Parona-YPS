import 'dart:convert';

/// Single source of truth for API and legal URLs.
/// Flip [useTls] to true only after the host serves a valid certificate.
class ApiConstants {
  static const String host = '168.144.112.34.sslip.io';

  /// Set true when HTTPS is live on [host]. Store launch requires this.
  static const bool useTls = true;

  static const Duration requestTimeout = Duration(seconds: 20);

  static const int maxOfflineQueueLength = 50;

  static const String privacyPolicyUrl = 'https://hagguggu.github.io/EventManagement/privacy.html';

  static String get scheme => useTls ? 'https' : 'http';

  static String get baseUrl => '$scheme://$host';

  /// Safely parses JSON. If the response is paginated (has a 'results' or 'events' key), 
  /// it extracts and returns the list. Otherwise, returns the decoded JSON.
  static dynamic parseResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      if (decoded.containsKey('results') && decoded['results'] is List) {
        return decoded['results'];
      }
      if (decoded.containsKey('events') && decoded['events'] is List) {
        return decoded['events'];
      }
    }
    return decoded;
  }

  /// Builds a Django-friendly URI from [baseUrl] + [endpoint].
  static Uri buildUri(String endpoint, {String? base}) {
    String cleanPath = endpoint.trim();
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    if (cleanPath.startsWith('api/')) {
      cleanPath = cleanPath.substring(4);
    }
    if (!cleanPath.contains('?') && !cleanPath.endsWith('/')) {
      cleanPath = '$cleanPath/';
    }
    final cleanBase = (base ?? baseUrl).endsWith('/')
        ? (base ?? baseUrl).substring(0, (base ?? baseUrl).length - 1)
        : (base ?? baseUrl);
    return Uri.parse('$cleanBase/$cleanPath');
  }
}

/// Staff leave body. Status is never set by the client.
Map<String, dynamic> buildStaffLeaveBody(String startDate, String reason) {
  return {
    'start_date': startDate,
    'end_date': startDate,
    'reason': reason,
  };
}
