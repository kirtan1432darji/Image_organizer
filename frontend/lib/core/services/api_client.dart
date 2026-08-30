import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../utils/result.dart';
import '../../models/classification_result_model.dart';
import '../../models/category_model.dart';

class ApiClient {
  late final Dio _dio;
  String _baseUrl;

  ApiClient({String baseUrl = ApiConstants.defaultBaseUrl}) : _baseUrl = baseUrl {
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
        onRequest: (options, handler) {
          // Add auth token if required or trace header
          options.headers['X-Request-Id'] = DateTime.now().millisecondsSinceEpoch.toString();
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Log or format server errors
          return handler.next(e);
        },
      ),
    );
  }

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl;
    _dio.options.baseUrl = newUrl;
  }

  String get baseUrl => _baseUrl;

  /// Classify a single screenshot's OCR metadata via ASP.NET Core AI backend
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
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return Result.success(ClassificationResultModel.fromJson(data as Map<String, dynamic>));
      } else {
        return Result.failure('Server returned code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return _handleDioError<ClassificationResultModel>(e);
    } catch (e) {
      return Result.failure('Unexpected error during classification: $e');
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
        final list = (response.data['results'] as List<dynamic>?) ?? [];
        final results = list
            .map((item) => ClassificationResultModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return Result.success(results);
      } else {
        return Result.failure('Batch classification failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      return _handleDioError<List<ClassificationResultModel>>(e);
    } catch (e) {
      return Result.failure('Unexpected error: $e');
    }
  }

  /// Fetch remote category definitions from ASP.NET Core backend
  Future<Result<List<CategoryModel>>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data is List ? response.data : response.data['data'] as List;
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
