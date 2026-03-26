import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Adjust these if your backend is running on a different host/port.
  // If you're using Android emulator use 10.0.2.2 (host machine) and matching port.
  static const String backendHost = '10.0.0.6';
  static const int backendPort = 5000; // set this to your active API port
  static String get baseUrl => 'http://$backendHost:$backendPort/api';

  static const String tokenKey = 'energyToken';
  static const String usernameKey = 'energyUser';

  static Future<void> saveToken(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(usernameKey, username);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(usernameKey);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(usernameKey);
  }

  static Map<String, String> _jsonHeaders([String? token]) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final resp = await http.post(url,
        headers: _jsonHeaders(), body: jsonEncode({'username': username, 'email': email, 'password': password}));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final resp = await http.post(url,
        headers: _jsonHeaders(), body: jsonEncode({'email': email, 'password': password}));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getProfile([String? token]) async {
    token ??= await getToken();
    final url = Uri.parse('$baseUrl/auth/profile');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updateData) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/auth/profile');
    final resp = await http.put(url, headers: _jsonHeaders(token), body: jsonEncode(updateData));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getWalletInfo() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/info');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getWalletBalance() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/balance');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getWalletAddress() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/address');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getQrCode() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/qr-code');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getLeaderboard([int limit = 10]) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/leaderboard?limit=$limit');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getLeaderboardByCoins([int limit = 10]) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/leaderboard/coins?limit=$limit');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getUserRank() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/rank');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> recordEnergy(double imported, double exported, {int conversionRate = 10}) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/record');
    final resp = await http.post(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({'importedKWh': imported, 'exportedKWh': exported, 'conversionRate': conversionRate}));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getEnergyHistory([int limit = 30]) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/history?limit=$limit');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getEnergyStats([int days = 30]) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/stats?days=$days');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> processMeterReadings(List<Map<String, dynamic>> readings) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/meter-readings');
    final resp = await http.post(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({'readings': readings}));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> updateConversionRate(double newRate) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/conversion-rate');
    final resp = await http.put(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({'newRate': newRate}));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> transferCoins(String toUserId, {int yellowCoins = 0, int greenCoins = 0, int redCoins = 0, String note = ''}) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/transactions/transfer');
    final resp = await http.post(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({'toUserId': toUserId, 'yellowCoins': yellowCoins, 'greenCoins': greenCoins, 'redCoins': redCoins, 'note': note}));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getTransactionHistory([int limit = 50]) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/transactions/history?limit=$limit');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getReceivedTransactions([int limit = 30]) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/transactions/received?limit=$limit');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getSentTransactions([int limit = 30]) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/transactions/sent?limit=$limit');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getTransactionById(String id) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/transactions/$id');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Map<String, dynamic> _handleJsonResponse(http.Response resp) {
    final data = jsonDecode(resp.body.isNotEmpty ? resp.body : '{}');

    if (resp.statusCode >= 400 || data['success'] == false) {
      return {
        'success': false,
        'statusCode': resp.statusCode,
        'message': data['message'] ?? resp.reasonPhrase ?? 'Unknown error',
        'data': data['data'] ?? {},
      };
    }

    return {
      'success': true,
      'statusCode': resp.statusCode,
      'message': data['message'] ?? 'OK',
      'data': data['data'] ?? data,
    };
  }
}
