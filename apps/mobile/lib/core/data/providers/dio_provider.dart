import "package:dio/dio.dart";
import "package:notaro_mobile/app_constants.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "dio_provider.g.dart";

@riverpod
Dio dio(final Ref ref) {
  final options = BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {"Content-Type": "application/json"},
  );

  final dio = Dio(options);

  // Add logging or auth interceptors here if needed
  // dio.interceptors.add(LogInterceptor());

  return dio;
}
