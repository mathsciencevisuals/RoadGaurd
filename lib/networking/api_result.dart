class ApiResult<T> {
  const ApiResult._({
    this.data,
    this.message,
    this.statusCode,
    required this.isSuccess,
  });

  final T? data;
  final String? message;
  final int? statusCode;
  final bool isSuccess;

  bool get isFailure => !isSuccess;

  factory ApiResult.success({
    required T data,
    int? statusCode,
    String? message,
  }) {
    return ApiResult<T>._(
      data: data,
      statusCode: statusCode,
      message: message,
      isSuccess: true,
    );
  }

  factory ApiResult.failure({
    required String message,
    int? statusCode,
  }) {
    return ApiResult<T>._(
      message: message,
      statusCode: statusCode,
      isSuccess: false,
    );
  }
}
