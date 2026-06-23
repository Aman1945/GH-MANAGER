import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://gh-manager-backend.onrender.com/api',
);

void _log(String msg) {
  developer.log('🌐 API: $msg');
  print('🌐 API: $msg');
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  void init() {
    _log('Initializing with baseUrl: $baseUrl');
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 50),
      receiveTimeout: const Duration(seconds: 50),
    ));

    // Fire-and-forget pre-warm request to wake up Render free tier backend
    _preWarmBackend();

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

  void _preWarmBackend() {
    _dio.get('/health').catchError((_) => Response(requestOptions: RequestOptions()));
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
      final resData = response.data;
      if (resData is Map && resData['data'] != null) {
        return Map<String, dynamic>.from(resData['data'] as Map);
      }
      return {};
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Dashboard
  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      _log('Fetching admin dashboard...');
      final response = await _dio.get('/dashboard/admin');
      _log('Admin dashboard response: ${response.data}');
      final resData = response.data;
      if (resData is Map && resData['data'] != null) {
        final data = Map<String, dynamic>.from(resData['data'] as Map);
        _log('Extracted admin dashboard data: $data');
        return data;
      }
      _log('No data field in response');
      return {};
    } on DioException catch (e) {
      _log('ERROR in getAdminDashboard: ${_extractErrorMessage(e)}');
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getBMDashboard() async {
    try {
      _log('Fetching BM dashboard...');
      final response = await _dio.get('/dashboard/booking-manager');
      _log('BM dashboard response: ${response.data}');
      final resData = response.data;
      if (resData is Map && resData['data'] != null) {
        return Map<String, dynamic>.from(resData['data'] as Map);
      }
      return {};
    } on DioException catch (e) {
      _log('ERROR in getBMDashboard: ${_extractErrorMessage(e)}');
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getGHMDashboard() async {
    try {
      _log('Fetching GHM dashboard...');
      final response = await _dio.get('/dashboard/gh-manager');
      _log('GHM dashboard response: ${response.data}');
      final resData = response.data;
      if (resData is Map && resData['data'] != null) {
        return Map<String, dynamic>.from(resData['data'] as Map);
      }
      return {};
    } on DioException catch (e) {
      _log('ERROR in getGHMDashboard: ${_extractErrorMessage(e)}');
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

  // Guest Houses
  Future<List<dynamic>> getGuestHouses() async {
    try {
      final response = await _dio.get('/guest-houses');
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return List<dynamic>.from(data['data'] as List);
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Maintenance/Room Reports
  Future<List<dynamic>> getMaintenanceRequests() async {
    try {
      final response = await _dio.get('/maintenance');
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return List<dynamic>.from(data['data'] as List);
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> createMaintenanceRequest(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/maintenance', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> resolveMaintenanceRequest(String id) async {
    try {
      final response = await _dio.patch('/maintenance/$id/resolve');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Sessions (Admin)
  Future<Map<String, dynamic>> getSessions() async {
    try {
      _log('Fetching admin sessions...');
      final response = await _dio.get('/admin/sessions');
      _log('Sessions response: ${response.data}');
      if (response.data is Map && response.data['data'] != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {};
    } on DioException catch (e) {
      _log('ERROR in getSessions: ${_extractErrorMessage(e)}');
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> logoutSession(String sessionId) async {
    try {
      _log('Logging out session: $sessionId');
      final response = await _dio.post('/admin/sessions/$sessionId/logout');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getLoginStats() async {
    try {
      _log('Fetching login stats...');
      final response = await _dio.get('/admin/login-stats');
      if (response.data is Map && response.data['data'] != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {};
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      _log('User logout...');
      final response = await _dio.post('/auth/logout');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    try {
      _log('Changing password...');
      final response = await _dio.post('/password-change', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword
      });
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }
}
