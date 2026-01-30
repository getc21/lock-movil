import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bellezapp/services/api_service.dart';
import 'package:bellezapp/config/api_config.dart';
import 'package:bellezapp/models/quotation.dart';
import 'package:bellezapp/controllers/auth_controller.dart';
import 'package:get/get.dart';

class QuotationService {
  final ApiService _apiService = ApiService.instance;

  String get _baseUrl => ApiConfig.baseUrl;
  
  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // Intentar obtener token del AuthController primero
    String? token;
    if (Get.isRegistered<AuthController>()) {
      final authController = Get.find<AuthController>();
      token = authController.token;
    }
    
    // Si no hay token en AuthController, usar el de ApiService
    token ??= _apiService.authToken;
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  Future<List<Quotation>> getQuotations({
    String? storeId,
    String? customerId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, String>{};
      if (storeId != null) params['storeId'] = storeId;
      if (customerId != null) params['customerId'] = customerId;
      if (status != null) params['status'] = status;
      if (startDate != null) params['startDate'] = startDate.toIso8601String();
      if (endDate != null) params['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse('$_baseUrl/quotations').replace(queryParameters: params);
      final response = await http.get(uri, headers: _buildHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final quotationsList = data['data']['quotations'] as List;
          return quotationsList.map((e) => Quotation.fromMap(e as Map<String, dynamic>)).toList();
        }
      }
      throw Exception('Failed to load quotations');
    } catch (e) {
      rethrow;
    }
  }

  Future<Quotation> getQuotation(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/quotations/$id'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return Quotation.fromMap(data['data']['quotation']);
        }
      }
      throw Exception('Failed to load quotation');
    } catch (e) {
      rethrow;
    }
  }

  Future<Quotation> createQuotation({
    required List<Map<String, dynamic>> items,
    required String storeId,
    String? customerId,
    String? discountId,
    double discountAmount = 0.0,
    String? paymentMethod,
    String? userId,
    DateTime? expirationDate,
  }) async {
    try {
      final body = {
        'items': items,
        'storeId': storeId,
        'customerId': customerId,
        'discountId': discountId,
        'discountAmount': discountAmount,
        'paymentMethod': paymentMethod,
        'userId': userId,
        'expirationDate': expirationDate?.toIso8601String(),
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/quotations'),
        headers: _buildHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return Quotation.fromMap(data['data']['quotation']);
        }
      }
      throw Exception('Failed to create quotation');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> convertQuotationToOrder(
    String quotationId, {
    String? paymentMethod,
  }) async {
    try {
      final body = paymentMethod != null
          ? {'paymentMethod': paymentMethod}
          : {};
      
      final response = await http.post(
        Uri.parse('$_baseUrl/quotations/$quotationId/convert'),
        headers: _buildHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      throw Exception('Failed to convert quotation to order');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteQuotation(String quotationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/quotations/$quotationId'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      throw Exception('Failed to delete quotation');
    } catch (e) {
      rethrow;
    }
  }
}
