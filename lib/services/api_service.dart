import 'package:dio/dio.dart';

class ApiService {
  late Dio _dio;
  String _baseUrl = 'http://localhost:5000';

  ApiService() {
    _initDio();
  }

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl;
    _dio.options.baseUrl = _baseUrl;
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 90), // XAI can take a long time
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// Send averaged sensor data to prediction API
  /// [sensorValues] must be a List of exactly 10 doubles corresponding to the sensors MQ9, MQ4, etc.
  Future<Map<String, dynamic>> predict({
    required String deviceId,
    required List<double> sensorValues,
  }) async {
    try {
      final response = await _dio.post(
        '/enose_greentea/predict',
        data: {
          'device_id': deviceId,
          'data': [sensorValues],
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }



  /// Get list of devices with prediction histories
  Future<List<String>> getDevices() async {
    try {
      final response = await _dio.get('/enose_greentea/devices');
      final data = response.data as Map<String, dynamic>;
      final list = data['devices'] as List<dynamic>;
      return list.map((item) => item.toString()).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Test server connection
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/enose_greentea/health');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['status'] == 'running';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return "Gagal koneksi ke API server (Connection Timeout). Silakan cek apakah server menyala.";
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return "Server terlalu lama merespons (Read Timeout). Kemungkinan server sedang berat memproses XAI.";
    } else if (error.response != null) {
      return "Server Error (${error.response?.statusCode}): ${error.response?.statusMessage}";
    } else {
      return "Terjadi masalah jaringan: ${error.message}";
    }
  }
}
