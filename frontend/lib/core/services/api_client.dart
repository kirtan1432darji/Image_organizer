import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../utils/result.dart';
import '../../models/classification_result_model.dart';
import '../../models/category_model.dart';
import '../../models/screenshot_model.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  String _baseUrl = ApiConstants.defaultBaseUrl;
  final _secureStorage = const FlutterSecureStorage();
  String? _accessToken;
  String? _refreshToken;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Client-Platform': 'Flutter',
          'X-Client-Version': '1.0.0',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['X-Request-Id'] = DateTime.now().millisecondsSinceEpoch.toString();
          
          _accessToken ??= await _secureStorage.read(key: 'jwt_access_token');
          if (_accessToken != null && _accessToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // Handle 401 Unauthorized - Attempt Token Refresh
          if (e.response?.statusCode == 401 && _refreshToken != null) {
            final refreshed = await _attemptTokenRefresh();
            if (refreshed) {
              final opts = e.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_accessToken';
              try {
                final cloneReq = await _dio.fetch(opts);
                return handler.resolve(cloneReq);
              } catch (retryError) {
                return handler.next(e);
              }
            }
          }
          return handler.next(e);
        },
      ),
    );

    _loadCustomBaseUrl();
  }

  Future<void> _loadCustomBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString('custom_backend_url');
      if (customUrl != null && customUrl.isNotEmpty) {
        updateBaseUrl(customUrl);
      }
    } catch (_) {}
  }

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl.trim();
    if (_baseUrl.endsWith('/')) {
      _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
    }
    if (!_baseUrl.endsWith('/api')) {
      _baseUrl = '$_baseUrl/api';
    }
    _dio.options.baseUrl = _baseUrl;
  }

  String get baseUrl => _baseUrl;

  Future<void> setAuthTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _secureStorage.write(key: 'jwt_access_token', value: accessToken);
    await _secureStorage.write(key: 'jwt_refresh_token', value: refreshToken);
  }

  Future<void> clearAuthTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _secureStorage.delete(key: 'jwt_access_token');
    await _secureStorage.delete(key: 'jwt_refresh_token');
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      final token = await _secureStorage.read(key: 'jwt_refresh_token');
      if (token == null) return false;

      final response = await Dio(BaseOptions(baseUrl: _baseUrl)).post(
        '/auth/refresh',
        data: {'refresh_token': token},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = _unwrapData(response.data);
        if (data != null && data['access_token'] != null) {
          await setAuthTokens(data['access_token'] as String, data['refresh_token'] as String);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  dynamic _unwrapData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data') && responseData['data'] != null) {
        return responseData['data'];
      }
    }
    return responseData;
  }

  /// Authentication: Register or Login
  Future<Result<Map<String, dynamic>>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = _unwrapData(response.data);
      if (data != null && data['access_token'] != null) {
        await setAuthTokens(data['access_token'] as String, data['refresh_token'] as String);
        return Result.success(Map<String, dynamic>.from(data as Map));
      }
      return Result.failure('Invalid login response');
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<Result<Map<String, dynamic>>> register(String name, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      final data = _unwrapData(response.data);
      if (data != null && data['access_token'] != null) {
        await setAuthTokens(data['access_token'] as String, data['refresh_token'] as String);
        return Result.success(Map<String, dynamic>.from(data as Map));
      }
      return Result.failure('Invalid register response');
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Batch Scan & Upsert Screenshot Metadata
  Future<Result<List<ScreenshotModel>>> batchScanScreenshots(List<ScreenshotModel> screenshots) async {
    try {
      final payload = {
        'screenshots': screenshots.map((s) => {
          'device_asset_id': s.deviceAssetId,
          'image_id': s.deviceAssetId,
          'file_path': s.filePath,
          'image_path': s.filePath,
          'file_name': s.fileName,
          'file_size': s.fileSize,
          'width': s.width,
          'height': s.height,
          'captured_date': s.createdAt.toIso8601String(),
          'source_app': s.sourceApp,
          'ocr_text': s.ocrText,
          'is_favorite': s.isFavorite,
          'is_reviewed': s.isReviewed,
          'is_mock': s.isMock,
        }).toList()
      };

      final response = await _dio.post('/screenshots/batch', data: payload);
      if (response.statusCode == 200) {
        final data = _unwrapData(response.data);
        final list = (data['screenshots'] as List<dynamic>?) ?? [];
        final models = list.map((m) => ScreenshotModel.fromJson(m as Map<String, dynamic>)).toList();
        return Result.success(models);
      }
      return Result.failure('Batch scan failed: ${response.statusCode}');
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return Result.failure('Unexpected error: $e');
    }
  }

  /// Classify a single screenshot
  Future<Result<ClassificationResultModel>> classifyScreenshot({
    required String screenshotId,
    required String fileName,
    required String ocrText,
    String? existingCategory,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.classifyScreenshot,
        data: {
          'screenshot_id': screenshotId,
          'file_name': fileName,
          'ocr_text': ocrText,
          'existing_category': existingCategory,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = _unwrapData(response.data);
        return Result.success(ClassificationResultModel.fromJson(data as Map<String, dynamic>));
      }
      return Result.failure('Server returned code: ${response.statusCode}');
    } on DioException catch (e) {
      return _handleDioError<ClassificationResultModel>(e);
    } catch (e) {
      return Result.failure('Unexpected error: $e');
    }
  }

  /// Batch classify multiple screenshot OCR records
  Future<Result<List<ClassificationResultModel>>> batchClassifyScreenshots(
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.batchClassify,
        data: {'items': items},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = _unwrapData(response.data);
        final list = (data['results'] as List<dynamic>?) ?? [];
        final results = list
            .map((item) => ClassificationResultModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return Result.success(results);
      }
      return Result.failure('Batch classification failed: ${response.statusCode}');
    } on DioException catch (e) {
      return _handleDioError<List<ClassificationResultModel>>(e);
    } catch (e) {
      return Result.failure('Unexpected error: $e');
    }
  }

  /// Toggle Favorite
  Future<Result<bool>> toggleFavorite(String id, bool isFavorite) async {
    try {
      final response = await _dio.patch('/screenshots/$id/favorite?isFavorite=$isFavorite');
      final data = _unwrapData(response.data);
      return Result.success(data == true || data == 1);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Mark Reviewed
  Future<Result<bool>> markReviewed(String id, [bool isReviewed = true]) async {
    try {
      final response = await _dio.patch('/screenshots/$id/review?isReviewed=$isReviewed');
      final data = _unwrapData(response.data);
      return Result.success(data == true || data == 1);
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  /// Fetch remote categories
  Future<Result<List<CategoryModel>>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      if (response.statusCode == 200 && response.data != null) {
        final list = _unwrapData(response.data) as List;
        final categories = list
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Result.success(categories);
      }
      return Result.failure('Failed to fetch categories: ${response.statusCode}');
    } on DioException catch (e) {
      return _handleDioError<List<CategoryModel>>(e);
    } catch (e) {
      return Result.failure('Error fetching categories: $e');
    }
  }

  /// Check backend connectivity & SQL Server status
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(
        ApiConstants.healthCheck,
        options: Options(sendTimeout: const Duration(seconds: 4)),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Result<T> _handleDioError<T>(DioException e) {
    String errorMsg = 'Network request failed';
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMsg = 'Connection timed out. Server is unreachable.';
        break;
      case DioExceptionType.badResponse:
        errorMsg = 'Server error (${e.response?.statusCode}): ${e.response?.statusMessage}';
        break;
      case DioExceptionType.connectionError:
        errorMsg = 'Cannot connect to ASP.NET Core backend at $_baseUrl. Check your network.';
        break;
      default:
        errorMsg = e.message ?? 'Unknown network error';
    }
    return Result.failure(errorMsg, e);
  }
}
