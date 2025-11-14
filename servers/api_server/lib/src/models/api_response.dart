import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.code,
    this.errors,
  });

  factory ApiResponse.success({
    required T data,
    String? message,
    int code = 200,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      code: code,
    );
  }

  factory ApiResponse.error({
    required String message,
    int code = 400,
    List<String>? errors,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      code: code,
      errors: errors,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  final bool success;
  final T? data;
  final String? message;
  final int? code;
  final List<String>? errors;

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  // Helper methods for common response types
  static Map<String, dynamic> successToJson(Map<String, dynamic> data, String? message) {
    return {
      'success': true,
      'data': data,
      'message': message,
      'code': 200,
    };
  }

  static Map<String, dynamic> successListToJson(List<Map<String, dynamic>> data, String? message) {
    return {
      'success': true,
      'data': data,
      'message': message,
      'code': 200,
    };
  }

  static Map<String, dynamic> errorToJson(String message, int code, [List<String>? errors]) {
    return {
      'success': false,
      'message': message,
      'code': code,
      'errors': errors,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, code: $code)';
  }
}
