import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Adjust these if your backend is running on a different host/port.
  // If you're using Android emulator use 10.0.2.2 (host machine) and matching port.
  static const String backendHost = '192.168.254.44';
  static const int backendPort = 5000; // set this to your active API port
  static String get baseUrl => 'http://$backendHost:$backendPort/api';

  static const String tokenKey = 'energyToken';
  static const String userNameKey = 'energyUser';
  static const String userIdKey = 'energyUserId';

  static Future<void> saveToken(String token, String name, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userNameKey, name);
    await prefs.setString(userIdKey, userId);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userIdKey);
  }

  static Map<String, String> _jsonHeaders([String? token]) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register(
      String userId, String userType, String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final resp = await http.post(url,
        headers: _jsonHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'user_type': userType,
          'name': name,
          'email': email,
          'password': password,
        }));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> login(String userId, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final resp = await http.post(url,
        headers: _jsonHeaders(),
        body: jsonEncode({'user_id': userId, 'password': password}));
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

  // ── Wallet ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getCoinValues() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/coin-values');
    final resp = await http.get(url, headers: _jsonHeaders(token));
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

  /// Prosumer sends [amountRs] worth of energy to [buyerId].
  /// Yellow coins are deducted from sender; buyer receives green coins.
  /// Platform keeps 20% spread — logged in admin_profit table.
  static Future<Map<String, dynamic>> sendEnergy(
      String buyerId, double amountRs) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/send-energy');
    final resp = await http.post(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({'buyer_id': buyerId, 'amount_rs': amountRs}));
    return _handleJsonResponse(resp);
  }

  /// Prosumer sells [yellowAmount] yellow coins; [buyerId] receives green coins.
  /// Platform takes 20% — buyer receives (yellowAmount × Rs4 × 0.80) / Rs7 green coins.
  static Future<Map<String, dynamic>> sellYellowCoins(
      String buyerId, double yellowAmount) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/sell-yellow');
    final resp = await http.post(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({'buyer_id': buyerId, 'amount': yellowAmount}));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> transferGreenCoins(
      String receiverId, double amount, {String note = ''}) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/transfer-green');
    final resp = await http.post(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({
          'receiver_id': receiverId,
          'amount': amount,
          'note': note,
        }));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> offsetRedCoins(double amount) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/offset-red');
    final resp = await http.post(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({'amount': amount}));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getLeaderboard([int limit = 10]) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/leaderboard?limit=$limit');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getSystemTotals() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/wallet/system-totals');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  // ── Weather ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getWeatherForecast() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/weather/forecast');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  // ── Energy ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getEnergyTotals() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/totals');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getEnergyReadings() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/readings');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getCycleBreakdown() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/cycles');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getCoinGenerationHistory() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/coin-history');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> recordEnergy(
      double importKwh, double exportKwh, int billingCycle) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/record');
    final resp = await http.post(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({
          'import_kwh': importKwh,
          'export_kwh': exportKwh,
          'billing_cycle': billingCycle,
        }));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getEnergyRates() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/rates');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> generateCoinsForCycle(int billingCycle) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/generate-coins');
    final resp = await http.post(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({'billing_cycle': billingCycle}));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getCycleSummary(int cycle) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/energy/cycle-summary/$cycle');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  // ── Transactions ──────────────────────────────────────────────────────────

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

  static Future<Map<String, dynamic>> getTransactionStats() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/transactions/stats');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  // ── Response handler ──────────────────────────────────────────────────────

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

  // ── Payments / Stripe ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPackages() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/payments/packages');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> createPaymentIntent(String packageId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/payments/create-payment-intent');
    final resp = await http.post(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({'package_id': packageId}));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> confirmPayment(String paymentIntentId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/payments/confirm');
    final resp = await http.post(url,
        headers: _jsonHeaders(token),
        body: jsonEncode({'payment_intent_id': paymentIntentId}));
    return _handleJsonResponse(resp);
  }

  static Future<Map<String, dynamic>> getPurchaseHistory() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/payments/history');
    final resp = await http.get(url, headers: _jsonHeaders(token));
    return _handleJsonResponse(resp);
  }
}
