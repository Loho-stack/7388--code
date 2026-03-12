import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LearnerDashboardApiService {
  static final LearnerDashboardApiService instance =
      LearnerDashboardApiService._internal();
  factory LearnerDashboardApiService() => instance;
  LearnerDashboardApiService._internal();

  static const String _baseUrl = 'https://elimupepe.loholearning.co.ke/api';
  static const String _webHost = 'https://elimupepe.loholearning.co.ke';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  Future<String?> _getToken() async {
    final passportToken = await _secureStorage.read(key: 'passport_token');
    if (passportToken != null && passportToken.isNotEmpty) {
      return passportToken;
    }

    final authToken = await _secureStorage.read(key: 'auth_token');
    if (authToken != null && authToken.isNotEmpty) {
      return authToken;
    }

    return null;
  }

  Future<List<dynamic>> fetchMenuItems({required String menuId}) async {
    final endpoints = _menuEndpoints(menuId);
    if (endpoints.isEmpty) {
      return [];
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No active session. Please log in again.');
    }

    try {
      if (menuId == 'interactive_books') {
        return _fetchInteractiveBooks(token);
      }

      if (menuId == 'non_interactive_books') {
        return _fetchNonInteractiveBooks(token);
      }

      for (final endpoint in endpoints) {
        try {
          final items = await _fetchEndpointItems(endpoint, token);
          final filtered = _filterItemsForMenu(items, menuId);
          if (filtered.isNotEmpty) {
            return filtered;
          }

          // Some endpoints can return empty arrays for a user; keep trying fallbacks.
          debugPrint('Learner API [$menuId] -> $endpoint returned empty. Trying next fallback.');
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            debugPrint('Learner API [$menuId] -> $endpoint (404 fallback)');
            continue;
          }
          rethrow;
        }
      }

      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('Access denied. Student account required.');
      }
      if (e.response?.statusCode == 429) {
        throw Exception('Too many requests. Please try again in a minute.');
      }

      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'] ?? responseData['error'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception('Could not load data from learner API.');
    } catch (e) {
      throw Exception('Unexpected API error: $e');
    }
  }

  Future<String?> resolveItemContentUrl({
    required String menuId,
    required Map<String, dynamic> item,
  }) async {
    final direct = _extractUrlFromMap(item);
    if (direct != null) {
      return direct;
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final id = item['id']?.toString();
    final quizId = item['quiz_id']?.toString();
    final detailEndpoints = _detailEndpoints(menuId, id: id, quizId: quizId);

    for (final endpoint in detailEndpoints) {
      try {
        final response = await _dio.get(
          endpoint,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
        );

        final nestedUrl = _extractUrlFromAny(response.data);
        if (nestedUrl != null) {
          debugPrint('Resolved content URL [$menuId] from $endpoint');
          return nestedUrl;
        }
      } on DioException {
        // Keep trying fallback detail endpoints.
      }
    }

    if (menuId == 'learning_areas' && id != null && id.isNotEmpty) {
      final linked = await _resolveLearningAreaLinkedUrl(id, token);
      if (linked != null) {
        return linked;
      }
    }

    return null;
  }

  Future<String?> fetchWebviewLoginUrl({String? targetUrl}) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    // Preferred flow: generate a single-use token and build /api/webview-auth magic URL.
    try {
      final tokenResponse = await _dio.post(
        '/student/generate-webview-token',
        options: Options(headers: headers),
      );

      final webviewToken = _extractGeneratedWebviewToken(tokenResponse.data);
      if (webviewToken != null) {
        final intendedPath = _buildIntendedPath(targetUrl);
        final magicUrl = Uri.parse('$_webHost/api/webview-auth').replace(
          queryParameters: {
            'token': webviewToken,
            if (intendedPath != null && intendedPath.isNotEmpty)
              'intended': intendedPath,
          },
        );
        return magicUrl.toString();
      }
    } on DioException {
      // Fall back to legacy endpoint if the new one is not available.
    }

    // Legacy fallback for older backend deployments.
    final parameterCandidates = <Map<String, dynamic>>[
      if (targetUrl != null && targetUrl.isNotEmpty)
        {'target_url': targetUrl, 'redirect_url': targetUrl, 'url': targetUrl},
      const {},
    ];

    for (final queryParameters in parameterCandidates) {
      try {
        final response = await _dio.get(
          '/student/webview-token',
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
          options: Options(headers: headers),
        );

        final url = _extractWebviewLoginUrl(response.data);
        if (url != null) {
          return url;
        }
      } on DioException {
        // Try next parameter shape or fallback without query parameters.
      }
    }

    return null;
  }

  String? _buildIntendedPath(String? targetUrl) {
    if (targetUrl == null || targetUrl.trim().isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(targetUrl.trim());
    if (parsed == null) {
      return null;
    }

    // If caller already passed a relative route (e.g. /file/1), keep it as-is.
    if (!parsed.hasScheme && targetUrl.trim().startsWith('/')) {
      return targetUrl.trim();
    }

    final host = parsed.host.toLowerCase();
    if (host != 'elimupepe.loholearning.co.ke') {
      return null;
    }

    final path = parsed.path.isEmpty ? '/' : parsed.path;
    if (parsed.query.isEmpty) {
      return path;
    }
    return '$path?${parsed.query}';
  }

  String? _extractGeneratedWebviewToken(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    final direct = payload['token'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['token'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim();
      }
    }

    return null;
  }

  Future<String?> _resolveLearningAreaLinkedUrl(String courseId, String token) async {
    final candidates = <String, Map<String, dynamic>>{
      '/student/books': {'course_id': courseId},
      '/student/elibrary': {'course_id': courseId},
      '/student/quizzes': {'course_id': courseId},
    };

    for (final entry in candidates.entries) {
      try {
        final response = await _dio.get(
          entry.key,
          queryParameters: entry.value,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
        );

        final items = _extractItems(response.data);
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final url = _extractUrlFromMap(item);
            if (url != null) {
              debugPrint('Resolved learning area URL via ${entry.key}?course_id=$courseId');
              return url;
            }
          }
        }
      } on DioException {
        // Try the next candidate endpoint.
      }
    }

    return null;
  }

  Future<List<dynamic>> _fetchInteractiveBooks(String token) async {
    final elibrary = await _fetchEndpointItems('/student/elibrary', token);
    final mapItems = elibrary.whereType<Map<String, dynamic>>().toList();
    return _dedupeByStableKey(mapItems);
  }

  Future<List<dynamic>> _fetchNonInteractiveBooks(String token) async {
    final books = await _fetchEndpointItems('/student/books', token);
    final elibrary = await _fetchEndpointItems('/student/elibrary', token);

    final bookMaps = books.whereType<Map<String, dynamic>>().toList();
    final elibraryIds = elibrary
        .whereType<Map<String, dynamic>>()
        .map((item) => item['id']?.toString())
        .whereType<String>()
        .toSet();

    final nonOverlap = bookMaps
        .where((item) => !elibraryIds.contains(item['id']?.toString()))
        .toList();

    if (nonOverlap.isNotEmpty) {
      return _dedupeByStableKey(nonOverlap);
    }

    return _dedupeByStableKey(bookMaps);
  }

  Future<List<dynamic>> _fetchEndpointItems(String endpoint, String token) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    List<dynamic> getItems = [];
    try {
      final response = await _dio.get(
        endpoint,
        options: Options(headers: headers),
      );
      getItems = _extractItems(response.data);
      if (getItems.isNotEmpty) {
        debugPrint('Learner API -> GET $endpoint returned ${getItems.length} items');
        return getItems;
      }

      debugPrint('Learner API -> GET $endpoint returned 0 items, trying POST fallback');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Try POST fallback for deployments that expose these via POST.
        debugPrint('Learner API -> GET $endpoint returned 404, trying POST fallback');
      } else {
        // For non-404 failures, still try POST once before rethrowing.
        debugPrint('Learner API -> GET $endpoint failed (${e.response?.statusCode}), trying POST fallback');
      }
    }

    try {
      final response = await _dio.post(
        endpoint,
        data: const {},
        options: Options(headers: headers),
      );
      final postItems = _extractItems(response.data);
      if (postItems.isNotEmpty) {
        debugPrint('Learner API -> POST $endpoint returned ${postItems.length} items');
      } else {
        debugPrint('Learner API -> POST $endpoint returned 0 items');
      }
      return postItems;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  List<dynamic> _filterItemsForMenu(List<dynamic> items, String menuId) {
    final mapItems = items.whereType<Map<String, dynamic>>().toList();
    if (mapItems.isEmpty) {
      return items;
    }

    switch (menuId) {
      case 'interactive_books':
        // Prefer items that look interactive; if none are marked, use elibrary-like items.
        final interactive = mapItems
            .where(
              (item) =>
                  item['run_url'] != null ||
                  item['interactive_url'] != null ||
                  item['is_interactive'] == true,
            )
            .toList();
        if (interactive.isNotEmpty) {
          return _dedupeByStableKey(interactive);
        }
        final elibraryStyle = mapItems.where((item) => item['book_url'] != null).toList();
        return _dedupeByStableKey(elibraryStyle.isNotEmpty ? elibraryStyle : mapItems);

      case 'non_interactive_books':
        final nonInteractive = mapItems
            .where(
              (item) =>
                  item['book_url'] != null &&
                  item['run_url'] == null &&
                  item['interactive_url'] == null,
            )
            .toList();
        return _dedupeByStableKey(nonInteractive.isNotEmpty ? nonInteractive : mapItems);

      case 'esoma_kids':
        final kids = mapItems
            .where(
              (item) =>
                  (item['publisher']?.toString().toLowerCase().contains('ubongo') ?? false) ||
                  (item['title']?.toString().toLowerCase().contains('akili') ?? false),
            )
            .toList();
        return _dedupeByStableKey(kids.isNotEmpty ? kids : mapItems);

      default:
        return _dedupeByStableKey(mapItems);
    }
  }

  List<Map<String, dynamic>> _dedupeByStableKey(List<Map<String, dynamic>> items) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final item in items) {
      final key =
          item['id']?.toString() ?? item['quiz_id']?.toString() ?? item['title']?.toString() ?? item.toString();
      if (seen.add(key)) {
        result.add(item);
      }
    }

    return result;
  }

  List<String> _detailEndpoints(
    String menuId, {
    String? id,
    String? quizId,
  }) {
    final itemId = id ?? quizId;
    if (itemId == null || itemId.isEmpty) {
      return [];
    }

    switch (menuId) {
      case 'learning_areas':
        return ['/student/courses/$itemId'];
      case 'interactive_books':
      case 'non_interactive_books':
      case 'esoma_kids':
        return ['/student/books/$itemId', '/student/elibrary/$itemId'];
      case 'virtual_labs':
        return ['/student/labs/$itemId'];
      case 'elimu_quest':
      case 'games':
      case 'leaderboard':
      case 'my_questions':
        return ['/student/quizzes/$itemId'];
      default:
        return [];
    }
  }

  String? _extractUrlFromAny(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final direct = _extractUrlFromMap(payload);
      if (direct != null) {
        return direct;
      }

      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        final nested = _extractUrlFromMap(data);
        if (nested != null) {
          return nested;
        }
      }
      if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
        return _extractUrlFromMap(data.first as Map<String, dynamic>);
      }

      final books = payload['books'];
      if (books is List && books.isNotEmpty && books.first is Map<String, dynamic>) {
        return _extractUrlFromMap(books.first as Map<String, dynamic>);
      }
    }
    return null;
  }

  String? _extractUrlFromMap(Map<String, dynamic> item) {
    final url = item['book_url'] ??
        item['course_url'] ??
        item['quiz_url'] ??
        item['run_url'] ??
        item['url'] ??
        item['link'] ??
        item['pdf_url'] ??
        item['resource_url'] ??
        item['interactive_url'];

    if (url is String && url.trim().isNotEmpty) {
      return url.trim();
    }
    return null;
  }

  String? _extractWebviewLoginUrl(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    final direct = payload['webview_login_url'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['webview_login_url'] ?? data['url'] ?? data['login_url'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim();
      }
    }

    final fallback = payload['url'] ?? payload['login_url'];
    if (fallback is String && fallback.trim().isNotEmpty) {
      return fallback.trim();
    }

    return null;
  }

  List<dynamic> _extractItems(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final bodyData = data['data'];
      if (bodyData is List) {
        return bodyData;
      }

      if (bodyData is Map<String, dynamic>) {
        if (bodyData['books'] is List) {
          return bodyData['books'] as List<dynamic>;
        }
        return [bodyData];
      }

      if (data['books'] is List) {
        return data['books'] as List<dynamic>;
      }
    }

    return [];
  }

  List<String> _menuEndpoints(String menuId) {
    switch (menuId) {
      case 'learning_areas':
        return ['/student/courses'];
      case 'interactive_books':
        return ['/student/elibrary'];
      case 'non_interactive_books':
        return ['/student/books'];
      case 'esoma_kids':
        return ['/student/elibrary', '/student/books'];
      case 'virtual_labs':
        return ['/student/labs'];
      case 'elimu_quest':
        return ['/student/quizzes'];
      case 'my_questions':
        return ['/student/questions'];
      case 'leaderboard':
        return ['/student/leaderboard'];
      case 'games':
        return ['/student/games'];
      default:
        return ['/student/elibrary'];
    }
  }
}
