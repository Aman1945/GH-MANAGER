import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://gh-manager-backend.onrender.com/api',
);

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await _prefs;
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final prefs = await _prefs;
          await prefs.remove('token');
        }
        handler.next(error);
      },
    ));
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'An error occurred';
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Dashboard
  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await _dio.get('/dashboard/admin');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getBMDashboard() async {
    try {
      final response = await _dio.get('/dashboard/booking-manager');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getGHMDashboard() async {
    try {
      final response = await _dio.get('/dashboard/gh-manager');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Leads
  Future<List<dynamic>> getLeads() async {
    try {
      final response = await _dio.get('/leads');
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return List<dynamic>.from(data['data'] as List);
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> createLead(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/leads', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Approvals
  Future<List<dynamic>> getPendingApprovals() async {
    try {
      final response = await _dio.get('/approvals/pending');
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return List<dynamic>.from(data['data'] as List);
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> approveLead(String id, String roomId) async {
    try {
      final response = await _dio.post(
        '/approvals/$id/approve',
        data: {'roomId': roomId},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> rejectLead(String id) async {
    try {
      final response = await _dio.post('/approvals/$id/reject');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Bookings
  Future<List<dynamic>> getBookings() async {
    try {
      final response = await _dio.get('/bookings');
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return List<dynamic>.from(data['data'] as List);
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> markPayment(String id) async {
    try {
      final response = await _dio.patch('/bookings/$id/payment');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> checkout(String id) async {
    try {
      final response = await _dio.patch('/bookings/$id/checkout');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Rooms
  Future<List<dynamic>> getRooms({String? guestHouseId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (guestHouseId != null) queryParams['guestHouseId'] = guestHouseId;
      final response = await _dio.get('/rooms', queryParameters: queryParams);
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return List<dynamic>.from(data['data'] as List);
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<List<dynamic>> getAvailability(
      String guestHouseId, String checkIn, String checkOut) async {
    try {
      final response = await _dio.get('/rooms/availability', queryParameters: {
        'guestHouseId': guestHouseId,
        'checkIn': checkIn,
        'checkOut': checkOut,
      });
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return List<dynamic>.from(data['data'] as List);
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }
}
