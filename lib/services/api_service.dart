import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ─────────────────────────────────────────────────────────────────
  // SET YOUR BACKEND IP HERE
  // ─────────────────────────────────────────────────────────────────
  // Flutter Web (Chrome)             → http://localhost:5000/api
  // Android Emulator                 → http://10.0.2.2:5000/api
  // Real Android phone on WiFi       → http://YOUR_PC_IP:5000/api
  //   (Find PC IP: open cmd → type "ipconfig" → look for IPv4 Address)
  //   Example: http://192.168.1.5:5000/api
  // PRODUCTION (Play Store release)  → https://your-deployed-server.com/api
  //   ↑ You MUST deploy the backend to a public server (e.g. Railway, Render,
  //     DigitalOcean) and set this URL to your real HTTPS server URL.
  // ─────────────────────────────────────────────────────────────────
  static const String _prodUrl = 'https://sreeram-inventory.onrender.com/api';
  static const String _devUrl = 'http://localhost:5000/api';
  static String get baseUrl => kIsWeb ? _devUrl : _prodUrl;
  
  static String get imageBaseUrl => baseUrl.replaceAll('/api', '');

  /// Returns a full URL for an image.
  /// If [path] is already a full URL (starts with http), returns it as-is.
  /// Otherwise, prepends [imageBaseUrl].
  static String? getFullImageUrl(String? path) {
    if (path == null || path.isEmpty || path == 'null') return null;
    if (path.startsWith('http')) return path;
    return '$imageBaseUrl$path';
  }

  static String? _token;
  static String? get token => _token;

  // ── Save token to device storage (persists after app restart) ──
  static Future<void> setToken(String t) async {
    _token = t;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', t);
  }

  // ── Load saved token on app start ──
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // ── Clear token on logout ──
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('username');
    await prefs.remove('branch');
  }

  // ── Save user info ──
  static Future<void> saveUserInfo(String username, String role, {String? branch}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('user_role', role);
    if (branch != null) {
      await prefs.setString('branch', branch);
    }
  }

  static Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<String?> getSavedBranch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('branch');
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ─────────────────────────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> adminLogin(
    String username,
    String password,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/admin/login'),
            headers: _headers,
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Cannot connect to server. Check your IP in api_service.dart',
      };
    }
  }

  static Future<Map<String, dynamic>> userLogin(
    String username,
    String password,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/user/login'),
            headers: _headers,
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {
        'success': false,
        'message':
            'Cannot connect to server. Check your IP in api_service.dart',
      };
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PRODUCTS
  // ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProducts({String? category, String? branch}) async {
    try {
      final List<String> queries = [];
      if (category != null) queries.add('category=${Uri.encodeComponent(category)}');
      if (branch != null) queries.add('branch=${Uri.encodeComponent(branch)}');
      
      final q = queries.isNotEmpty ? '?${queries.join('&')}' : '';
      final res = await http
          .get(Uri.parse('$baseUrl/products$q'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> data,
  ) async {
    try {
      final imagePath = data['image'] as String?;
      final bytes = data['webImageBytes'] as Uint8List?;

      if ((imagePath != null && imagePath.isNotEmpty && !kIsWeb) ||
          (kIsWeb && bytes != null)) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/products'),
        );
        request.headers.addAll(_headers);
        request.fields['name'] = data['name'].toString();
        request.fields['code'] = data['code'].toString();
        request.fields['unit'] = data['unit'].toString();
        request.fields['category'] = data['category'].toString();
        if (data['brand'] != null) {
          request.fields['brand'] = data['brand'].toString();
        }
        if (data['vendor'] != null) {
          request.fields['vendor'] = data['vendor'].toString();
        }

        if (kIsWeb && data['webImageBytes'] != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              data['webImageBytes'] as Uint8List,
              filename: 'upload.jpg',
            ),
          );
        } else if (imagePath != null && imagePath.isNotEmpty && !kIsWeb) {
          request.files.add(
            await http.MultipartFile.fromPath('image', imagePath),
          );
        }
        final streamedRes = await request.send().timeout(
          const Duration(seconds: 20),
        );
        final res = await http.Response.fromStream(streamedRes);
        return jsonDecode(res.body);
      } else {
        // Fallback or No image
        final res = await http
            .post(
              Uri.parse('$baseUrl/products'),
              headers: _headers,
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: 10));
        return jsonDecode(res.body);
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final imagePath = data['image'] as String?;
      // Use multipart if there is a NEW image (path or web bytes)
      final hasNewImage =
          (imagePath != null &&
              imagePath.isNotEmpty &&
              !kIsWeb &&
              !imagePath.startsWith('http') &&
              !imagePath.startsWith('/uploads')) ||
          (kIsWeb && data['webImageBytes'] != null);

      if (hasNewImage) {
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('$baseUrl/products/$id'),
        );
        request.headers.addAll(_headers);
        if (data['name'] != null) {
          request.fields['name'] = data['name'].toString();
        }
        if (data['code'] != null) {
          request.fields['code'] = data['code'].toString();
        }
        if (data['unit'] != null) {
          request.fields['unit'] = data['unit'].toString();
        }
        if (data['category'] != null) {
          request.fields['category'] = data['category'].toString();
        }
        if (data['brand'] != null) {
          request.fields['brand'] = data['brand'].toString();
        }
        if (data['isActive'] != null) {
          request.fields['isActive'] = data['isActive'].toString();
        }

        if (kIsWeb && data['webImageBytes'] != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              data['webImageBytes'] as Uint8List,
              filename: 'upload.jpg',
            ),
          );
        } else if (imagePath != null &&
            imagePath.isNotEmpty &&
            !kIsWeb &&
            !imagePath.startsWith('http') &&
            !imagePath.startsWith('/uploads')) {
          request.files.add(
            await http.MultipartFile.fromPath('image', imagePath),
          );
        }
        final streamedRes = await request.send().timeout(
          const Duration(seconds: 20),
        );
        final res = await http.Response.fromStream(streamedRes);
        return jsonDecode(res.body);
      } else {
        final res = await http
            .put(
              Uri.parse('$baseUrl/products/$id'),
              headers: _headers,
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: 10));
        return jsonDecode(res.body);
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> toggleProduct(String id) async {
    try {
      final res = await http
          .patch(Uri.parse('$baseUrl/products/$id/toggle'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteProduct(String id) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl/products/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAllShopsProducts({String? branch}) async {
    try {
      final q = branch != null ? '?branch=${Uri.encodeComponent(branch)}' : '';
      final res = await http
          .get(Uri.parse('$baseUrl/products/list/all-shops$q'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STOCK
  // ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStocks({String? branch}) async {
    try {
      final q = branch != null ? '?branch=${Uri.encodeComponent(branch)}' : '';
      final res = await http
          .get(Uri.parse('$baseUrl/stock$q'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStockAlerts() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/stock/alerts'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateMinLevel(
    String stockId,
    double minLevel,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/stock/$stockId/minlevel'),
            headers: _headers,
            body: jsonEncode({'minLevel': minLevel}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteStock(String id) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl/stock/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> clearStockAlerts(String id) async {
    try {
      final res = await http
          .put(Uri.parse('$baseUrl/stock/clear-alerts/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getTransactions({String? type}) async {
    try {
      final q = type != null ? '?type=$type' : '';
      final res = await http
          .get(
            Uri.parse('$baseUrl/stock/transactions/all$q'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/stock/transactions'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // CONTACTS
  // ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getContacts({String? category, String? branch}) async {
    try {
      final List<String> queries = [];
      if (category != null) queries.add('category=${Uri.encodeComponent(category)}');
      if (branch != null) queries.add('branch=${Uri.encodeComponent(branch)}');
      final q = queries.isNotEmpty ? '?${queries.join('&')}' : '';
      final res = await http
          .get(Uri.parse('$baseUrl/contacts$q'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createContact(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/contacts'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateContact(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/contacts/$id'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteContact(String id) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl/contacts/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // BRANCHES
  // ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getBranches() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/branches'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPublicBranches() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/branches/public'))
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createBranch(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/branches'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateBranch(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/branches/$id'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteBranch(String id) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl/branches/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // VENDORS
  // ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getVendors({String? branch}) async {
    try {
      final q = branch != null ? '?branch=${Uri.encodeComponent(branch)}' : '';
      final res = await http
          .get(Uri.parse('$baseUrl/vendors$q'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createVendor(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/vendors'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateVendor(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$baseUrl/vendors/$id'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteVendor(String id) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl/vendors/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // USERS (Admin Only)
  // ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUsers() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/auth/users'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserLoginHistory() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/auth/users/login-history'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/user/signup'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> toggleUserStatus(String id) async {
    try {
      final res = await http
          .put(Uri.parse('$baseUrl/auth/users/$id/toggle'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl/auth/users/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PASSWORD MANAGEMENT
  // ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> revealUserPassword(
    String id,
    String adminPassword,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/users/$id/reveal'),
            headers: _headers,
            body: jsonEncode({'adminPassword': adminPassword}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> changeUserPassword(
    String id,
    String newPassword,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/users/$id/change-password'),
            headers: _headers,
            body: jsonEncode({'newPassword': newPassword}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> changeAdminPassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/admin/change-password'),
            headers: _headers,
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Admin Forgot Password: Send OTP to main branch email ──────────
  static Future<Map<String, dynamic>> sendAdminForgotPasswordOtp() async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/admin/forgot-password'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Admin Reset Password with OTP ─────────────────────────────────
  static Future<Map<String, dynamic>> resetAdminPasswordWithOtp(
    String otp,
    String newPassword,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/admin/reset-password-otp'),
            headers: _headers,
            body: jsonEncode({'otp': otp, 'newPassword': newPassword}),
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // UNITS
  // ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUnits() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/units'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addUnit(String name) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/units'),
            headers: _headers,
            body: jsonEncode({'name': name}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteUnit(String name) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/units/delete'),
            headers: _headers,
            body: jsonEncode({'name': name}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
