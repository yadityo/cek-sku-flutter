// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Tambahkan kurung kurawal { } di sini
  static Future<http.Response> postRequest({
    required String baseUrl, 
    required String endpoint, 
    required Map<String, dynamic> body,
  }) async {
    final url = baseUrl.startsWith('http') 
        ? '$baseUrl$endpoint' 
        : 'http://$baseUrl:3000$endpoint';
    
    return await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
  }
}