import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
    this.code,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  factory ApiResponse.success({
    required T data,
    String? message,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      code: 200,
    );
  }

  factory ApiResponse.error({
    required String error,
    String? message,
  }) {
    return ApiResponse(
      success: false,
      error: error,
      message: message,
      code: 400,
    );
  }

  final bool success;
  final T? data;
  final String? error;
  final String? message;
  final int? code;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiResponse &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          data == other.data &&
          error == other.error &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode =>
      success.hashCode ^
      data.hashCode ^
      error.hashCode ^
      message.hashCode ^
      code.hashCode;

  @override
  String toString() {
    return 'ApiResponse(success: $success, data: $data, error: $error, '
        'message: $message, code: $code)';
  }
}
