import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../utils/result.dart';
import 'auth_service.dart';
import '../../models/auth_model.dart';
import '../../models/category_model.dart';
import '../../models/classification_result_model.dart';
import '../../models/folder_context_model.dart';
import '../../models/tag_model.dart';

class ApiClient {
  late final Dio _dio;
  String _baseUrl;
  final AuthService _authService;
  bool _isRefreshing = false;

  ApiClient({
    String baseUrl = ApiConstants.defaultBaseUrl,
    AuthService? authService,
  })  : _baseUrl = baseUrl,
        _authService = authService ?? AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Client-Platform': 'Flutter-Mobile',
          'X-Client-Version': '1.0.0',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 1. Inject Bearer token if available
          final token = _authService.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['X-Request-Id'] = DateTime.now().millisecondsSinceEpoch.toString();
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // 2. Handle 401 Unauthorized with token refresh retry
          if (e.response?.statusCode == 401 && !_isRefreshing) {
            final refreshToken = _authService.refreshToken;
            final accessToken = _authService.accessToken;
            if (refreshToken != null && accessToken != null) {
              _isRefreshing = true;
              try {
                final refreshResult = await _performTokenRefresh(accessToken, refreshToken);
                _isRefreshing = false;
                if (refreshResult.isSuccess) {
                  final newAuth = refreshResult.dataOrNull!;
                  await _authService.saveAuth(newAuth);

                  // Retry original request with new access token
                  final opts = e.requestOptions;
                  opts.headers['Authorization'] = 'Bearer ${newAuth.accessToken}';
                  final cloneReq = await _dio.fetch(opts);
                  return handler.resolve(cloneReq);
                } else {
                  await _authService.clearAuth();
                }
              } catch (_) {
                _isRefreshing = false;
                await _authService.clearAuth();
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  void updateBaseUrl(String newUrl) {
    var trimmed = newUrl.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    _baseUrl = trimmed;
    _dio.options.baseUrl = trimmed;
  }

  String get baseUrl => _baseUrl;

  /// Helper to safely unwrap standard backend ApiResponse envelope: { success, message, data, errors }
  dynamic _unwrapData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) {
        return responseData['data'];
      }
    }
    return responseData;
  }

  // ==================== AUTHENTICATION ====================

  Future<Result<AuthResponseModel>> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.authLogin,
        data: {
          'emailOrUsername': emailOrUsername,
          'password': password,
        },
      );

      final unwrapped = _unwrapData(response.data);
      if (unwrapped is Map<String, dynamic>) {
        final auth = AuthResponseModel.fromJson(unwrapped);
        await _authService.saveAuth(auth);
        return Result.success(auth);
      }
      return Result.failure('Invalid login response format');
    } on DioException catch (e) {
      return _handleDioError<AuthResponseModel>(e);
    } catch (e) {
      return Result.failure('Login failed: $e');
    }
  }

  Future<Result<AuthResponseModel>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.authRegister,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      final unwrapped = _unwrapData(response.data);
      if (unwrapped is Map<String, dynamic>) {
        final auth = AuthResponseModel.fromJson(unwrapped);
        await _authService.saveAuth(auth);
        return Result.success(auth);
      }
      return Result.failure('Invalid registration response');
    } on DioException catch (e) {
      return _handleDioError<AuthResponseModel>(e);
    } catch (e) {
      return Result.failure('Registration failed: $e');
    }
  }

  Future<Result<AuthResponseModel>> _performTokenRefresh(String token, String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.authRefresh,
        data: {
          'accessToken': token,
          'refreshToken': refreshToken,
        },
      );
      final unwrapped = _unwrapData(response.data);
      if (unwrapped is Map<String, dynamic>) {
        return Result.success(AuthResponseModel.fromJson(unwrapped));
      }
      return Result.failure('Refresh token failed');
    } catch (e) {
      return Result.failure('Token refresh error: $e');
    }
  }

  Future<void> logout() async {
    try {
      final rToken = _authService.refreshToken;
      if (rToken != null) {
        await _dio.post(ApiConstants.authLogout, data: {'refreshToken': rToken});
      }
    } catch (_) {}
    await _authService.clearAuth();
  }

  // ==================== SCREENSHOT SCAN & INDEXING ====================

  /// Scan & index a single screenshot metadata on the backend (with server-side classification)
  Future<Result<Map<String, dynamic>>> scanScreenshotMetadata({
    required String imageId, // Device asset ID
    required String imagePath,
    String? fileName,
    int? fileSize,
    String? thumbnailPath,
    required DateTime capturedDate,
    required String sourceApp,
    required int width,
    required int height,
    required String ocrText,
    String? visionDescription,
    String? hash,
    bool autoClassify = true,
  }) async {
    try {
      final name = fileName ?? (imagePath.isNotEmpty ? imagePath.split(RegExp(r'[/\\]')).last : '');
      final response = await _dio.post(
        ApiConstants.scanScreenshot,
        data: {
          'device_asset_id': imageId,
          'image_id': imageId,
          'file_path': imagePath,
          'image_path': imagePath,
          'file_name': name,
          'file_size': fileSize ?? 0,
          'thumbnail_path': thumbnailPath,
          'captured_date': capturedDate.toIso8601String(),
          'created_at': capturedDate.toIso8601String(),
          'source_app': sourceApp,
          'width': width,
          'height': height,
          'ocr_text': ocrText,
          'vision_description': visionDescription,
          'hash': hash,
          'auto_classify': autoClassify,
          // camelCase aliases for flexibility
          'imageId': imageId,
          'imagePath': imagePath,
          'fileName': name,
          'fileSize': fileSize ?? 0,
          'capturedDate': capturedDate.toIso8601String(),
          'sourceApp': sourceApp,
          'ocrText': ocrText,
        },
      );

      final unwrapped = _unwrapData(response.data);
      if (unwrapped is Map<String, dynamic>) {
        return Result.success(unwrapped);
      }
      return Result.failure('Unexpected scan response structure');
    } on DioException catch (e) {
      return _handleDioError<Map<String, dynamic>>(e);
    } catch (e) {
      return Result.failure('Scan upload error: $e');
    }
  }

  /// Batch scan multiple screenshot metadata items
  Future<Result<List<Map<String, dynamic>>>> batchScanScreenshots(
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.batchScan,
        data: {
          'screenshots': items,
          'items': items,
        },
      );

      final unwrapped = _unwrapData(response.data);
      if (unwrapped is List) {
        return Result.success(unwrapped.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      } else if (unwrapped is Map) {
        final list = (unwrapped['items'] ?? unwrapped['results']) as List?;
        if (list != null) {
          return Result.success(list.map((e) => Map<String, dynamic>.from(e as Map)).toList());
        }
      }
      return Result.success([]);
    } on DioException catch (e) {
      return _handleDioError<List<Map<String, dynamic>>>(e);
    } catch (e) {
      return Result.failure('Batch scan error: $e');
    }
  }

  /// Classify screenshot OCR text via AI backend
  Future<Result<ClassificationResultModel>> classifyScreenshot({
    required String screenshotId,
    required String fileName,
    required String ocrText,
    String? existingCategory,
    String sourceApp = '',
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.classifyScreenshot,
        data: {
          'ocrText': ocrText,
          'sourceApp': sourceApp,
          'screenshotId': screenshotId,
          'fileName': fileName,
        },
      );

      final unwrapped = _unwrapData(response.data);
      if (unwrapped is Map<String, dynamic>) {
        return Result.success(ClassificationResultModel.fromJson(unwrapped));
      }
      return Result.failure('Invalid classification response');
    } on DioException catch (e) {
      return _handleDioError<ClassificationResultModel>(e);
    } catch (e) {
      return Result.failure('Classification error: $e');
    }
  }

  /// Sprint 1.3: Classify screenshot with full metadata and folder hierarchy resolution
  Future<Result<ClassificationResultModel>> classifyScreenshotMetadata({
    String? screenshotId,
    String? fileName,
    String? filePath,
    required String ocrText,
    String? visionDescription,
    String? sourceApp,
    String? existingCategory,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.classificationClassify,
        data: {
          'screenshot_id': screenshotId,
          'file_name': fileName,
          'file_path': filePath,
          'ocr_text': ocrText,
          'vision_description': visionDescription,
          'source_app': sourceApp,
          'existing_category': existingCategory,
        },
      );

      final unwrapped = _unwrapData(response.data);
      if (unwrapped is Map<String, dynamic>) {
        return Result.success(ClassificationResultModel.fromJson(unwrapped));
      }
      return Result.failure('Invalid classification response');
    } on DioException catch (e) {
      return _handleDioError<ClassificationResultModel>(e);
    } catch (e) {
      return Result.failure('Classification error: $e');
    }
  }

  /// Sprint 1.3: Reclassify an existing screenshot
  Future<Result<ClassificationResultModel>> reclassifyScreenshot({
    required String screenshotId,
    bool forceReclassify = true,
    String? userHint,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.classificationReclassify,
        data: {
          'screenshot_id': screenshotId,
          'force_reclassify': forceReclassify,
          'user_hint': userHint,
        },
      );

      final unwrapped = _unwrapData(response.data);
      if (unwrapped is Map<String, dynamic>) {
        return Result.success(ClassificationResultModel.fromJson(unwrapped));
      }
      return Result.failure('Invalid reclassification response');
    } on DioException catch (e) {
      return _handleDioError<ClassificationResultModel>(e);
    } catch (e) {
      return Result.failure('Reclassification error: $e');
    }
  }

  /// Sprint 1.3: Fetch classification history for a screenshot
  Future<Result<List<Map<String, dynamic>>>> fetchClassificationHistory(String screenshotId) async {
    try {
      final response = await _dio.get('${ApiConstants.classificationHistory}/$screenshotId');
      final unwrapped = _unwrapData(response.data);
      if (unwrapped is List) {
        return Result.success(unwrapped.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
      return Result.success([]);
    } on DioException catch (e) {
      return _handleDioError<List<Map<String, dynamic>>>(e);
    } catch (e) {
      return Result.failure('History error: $e');
    }
  }

  /// Fetch paged screenshots from ASP.NET Core backend
  Future<Result<List<Map<String, dynamic>>>> fetchScreenshots({
    String? categoryId,
    String? subCategoryId,
    String? tag,
    String? sourceApp,
    bool? isFavorite,
    bool? isReviewed,
    bool? needsReview,
    String? searchTerm,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.screenshots,
        queryParameters: {
          if (categoryId != null && categoryId != 'all') 'categoryId': categoryId,
          if (subCategoryId != null) 'subCategoryId': subCategoryId,
          if (tag != null) 'tag': tag,
          if (sourceApp != null) 'sourceApp': sourceApp,
          if (isFavorite != null) 'isFavorite': isFavorite,
          if (isReviewed != null) 'isReviewed': isReviewed,
          if (needsReview != null) 'needsReview': needsReview,
          if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );

      final unwrapped = _unwrapData(response.data);
      if (unwrapped is Map && unwrapped['items'] is List) {
        final list = unwrapped['items'] as List;
        return Result.success(list.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      } else if (unwrapped is List) {
        return Result.success(unwrapped.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
      return Result.success([]);
    } on DioException catch (e) {
      return _handleDioError<List<Map<String, dynamic>>>(e);
    } catch (e) {
      return Result.failure('Failed to fetch screenshots: $e');
    }
  }

  /// Update screenshot metadata on backend
  Future<Result<bool>> updateScreenshot({
    required String id,
    String? categoryId,
    String? subCategoryId,
    List<String>? tags,
    bool? isFavorite,
  }) async {
    try {
      await _dio.put(
        '${ApiConstants.screenshots}/$id',
        data: {
          if (categoryId != null) 'categoryId': categoryId,
          if (subCategoryId != null) 'subCategoryId': subCategoryId,
          if (tags != null) 'tags': tags,
          if (isFavorite != null) 'isFavorite': isFavorite,
        },
      );
      return Result.success(true);
    } on DioException catch (e) {
      return _handleDioError<bool>(e);
    } catch (e) {
      return Result.failure('Update failed: $e');
    }
  }

  /// Toggle favorite on backend
  Future<Result<bool>> toggleFavorite(String id, [bool? isFavorite]) async {
    try {
      final response = await _dio.patch(
        '${ApiConstants.screenshots}/$id/favorite',
        queryParameters: {
          if (isFavorite != null) 'isFavorite': isFavorite,
        },
      );
      final unwrapped = _unwrapData(response.data);
      return Result.success(unwrapped == true);
    } on DioException catch (e) {
      return _handleDioError<bool>(e);
    } catch (e) {
      return Result.failure('Toggle favorite failed: $e');
    }
  }

  /// Toggle review on backend
  Future<Result<bool>> toggleReview(String id, [bool? isReviewed]) async {
    try {
      final response = await _dio.patch(
        '${ApiConstants.screenshots}/$id/review',
        queryParameters: {
          if (isReviewed != null) 'isReviewed': isReviewed,
        },
      );
      final unwrapped = _unwrapData(response.data);
      return Result.success(unwrapped == true);
    } on DioException catch (e) {
      return _handleDioError<bool>(e);
    } catch (e) {
      return Result.failure('Toggle review failed: $e');
    }
  }

  /// Delete screenshot metadata on backend
  Future<Result<bool>> deleteScreenshot(String id) async {
    try {
      await _dio.delete('${ApiConstants.screenshots}/$id');
      return Result.success(true);
    } on DioException catch (e) {
      return _handleDioError<bool>(e);
    } catch (e) {
      return Result.failure('Delete failed: $e');
    }
  }

  /// Fetch remote category definitions from ASP.NET Core backend
  Future<Result<List<CategoryModel>>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      final unwrapped = _unwrapData(response.data);
      if (unwrapped is List) {
        final categories = unwrapped
            .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return Result.success(categories);
      }
      return Result.success([]);
    } on DioException catch (e) {
      return _handleDioError<List<CategoryModel>>(e);
    } catch (e) {
      return Result.failure('Error fetching categories: $e');
    }
  }

  /// Fetch remote tag definitions from ASP.NET Core backend
  Future<Result<List<TagModel>>> fetchTags() async {
    try {
      final response = await _dio.get(ApiConstants.tags);
      final unwrapped = _unwrapData(response.data);
      if (unwrapped is List) {
        final tags = unwrapped
            .map((e) => TagModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return Result.success(tags);
      }
      return Result.success([]);
    } on DioException catch (e) {
      return _handleDioError<List<TagModel>>(e);
    } catch (e) {
      return Result.failure('Error fetching tags: $e');
    }
  }

  /// Sync offline changes with backend
  Future<Result<Map<String, dynamic>>> syncMetadata(Map<String, dynamic> syncPayload) async {
    try {
      final response = await _dio.post(
        ApiConstants.sync,
        data: syncPayload,
      );
      final unwrapped = _unwrapData(response.data);
      if (unwrapped is Map<String, dynamic>) {
        return Result.success(unwrapped);
      }
      return Result.success({});
    } on DioException catch (e) {
      return _handleDioError<Map<String, dynamic>>(e);
    } catch (e) {
      return Result.failure('Sync error: $e');
    }
  }

  /// Fetch smart folder AI context (Sprint 1.4)
  Future<Result<FolderContextModel>> fetchFolderContext(String categoryId) async {
    try {
      final response = await _dio.get(ApiConstants.folderContext(categoryId));
      final unwrapped = _unwrapData(response.data);
      if (unwrapped is Map<String, dynamic>) {
        return Result.success(FolderContextModel.fromJson(unwrapped));
      }
      return Result.failure('Unexpected response format for folder context');
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return Result.failure('Failed to fetch folder context: $e');
    }
  }

  /// Generate or refresh smart folder AI context (Sprint 1.4)
  Future<Result<FolderContextModel>> generateFolderContext(String categoryId) async {
    try {
      final response = await _dio.post(ApiConstants.generateFolderContext(categoryId));
      final unwrapped = _unwrapData(response.data);
      if (unwrapped is Map<String, dynamic>) {
        return Result.success(FolderContextModel.fromJson(unwrapped));
      }
      return Result.failure('Unexpected response format when generating folder context');
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return Result.failure('Failed to generate folder context: $e');
    }
  }

  /// Check backend connectivity
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
        errorMsg = 'Connection timed out. Backend is unreachable at $_baseUrl.';
        break;
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          errorMsg = resData['message'].toString();
        } else {
          errorMsg = 'Server returned error ($status).';
        }
        break;
      case DioExceptionType.connectionError:
        errorMsg = 'Cannot connect to backend at $_baseUrl. Check network / IP.';
        break;
      default:
        errorMsg = e.message ?? 'Unknown network error';
    }
    debugPrint('[ApiClient Error] $errorMsg (URL: ${e.requestOptions.uri})');
    return Result.failure(errorMsg, e);
  }
}
