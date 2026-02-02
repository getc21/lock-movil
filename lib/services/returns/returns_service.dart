import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/returns/return_models.dart';
import '../../config/api_config.dart';

class ReturnsService {
  final Dio dio;
  
  // Usar baseUrl centralizado de ApiConfig
  String get baseUrl => ApiConfig.baseUrl;

  ReturnsService(this.dio) {
    _configureDio();
  }

  // Configurar Dio con autenticación
  void _configureDio() {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(seconds: 60);
    
    // Agregar interceptor para token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  // Crear solicitud de devolución
  Future<ReturnRequest> createReturnRequest({
    required String orderId,
    required ReturnType type,
    required List<ReturnItem> items,
    required RefundMethod refundMethod,
    required ReturnReasonCategory reasonCategory,
    required String returnReasonDetails,
    List<String>? attachmentUrls,
    String? notes,
    required String storeId,
  }) async {
    try {
      final requestData = {
        'orderId': orderId,
        'type': type.value,
        'items': items.map((i) => i.toJson()).toList(),
        'refundMethod': refundMethod.value,
        'reasonCategory': reasonCategory.value,
        'reasonDetails': returnReasonDetails.isNotEmpty ? returnReasonDetails : 'Sin detalles especificados',
        'attachmentUrls': attachmentUrls ?? [],
        'notes': notes != null && notes.isNotEmpty ? [notes] : [],
        'storeId': storeId,
      };
      
      print('DEBUG ReturnsService: Enviando solicitud de devolución');
      print('Datos: $requestData');
      
      final response = await dio.post(
        '$baseUrl/returns/request',
        data: requestData,
      );

      print('DEBUG ReturnsService: Respuesta exitosa');
      print('Response: ${response.data}');
      
      return ReturnRequest.fromJson(response.data['returnRequest']);
    } catch (e) {
      print('DEBUG ReturnsService ERROR: $e');
      if (e is DioException) {
        print('DioException response: ${e.response?.data}');
        print('DioException status: ${e.response?.statusCode}');
      }
      throw Exception('Error al crear solicitud de devolución: $e');
    }
  }

  // Obtener devoluciones con filtros
  Future<Map<String, dynamic>> getReturnsWithFilters({
    required String storeId,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
    String? refundMethod,
  }) async {
    try {
      final queryParams = {
        'storeId': storeId,
        if (status != null) 'status': status,
        if (type != null) 'type': type,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (customerId != null) 'customerId': customerId,
        if (refundMethod != null) 'refundMethod': refundMethod,
      };

      print('DEBUG ReturnsService: Obteniendo devoluciones con filtros');
      print('Query params: $queryParams');

      final response = await dio.get(
        '$baseUrl/returns',
        queryParameters: queryParams,
      );

      print('DEBUG ReturnsService: Respuesta exitosa');
      print('Response data: ${response.data}');

      final returnsList = (response.data['returns'] as List?)?.map((r) {
        try {
          return ReturnRequest.fromJson(r as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing return item: $e');
          print('Item data: $r');
          rethrow;
        }
      }).toList() ?? [];

      return {
        'returns': returnsList,
        'summary': response.data['summary'],
      };
    } catch (e) {
      print('DEBUG ReturnsService ERROR: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Error al obtener devoluciones: $e');
    }
  }

  // Aprobar solicitud de devolución
  Future<ReturnRequest> approveReturnRequest({
    required String returnRequestId,
    String? approvalNotes,
  }) async {
    try {
      final response = await dio.patch(
        '$baseUrl/returns/$returnRequestId/approve',
        data: {
          'approvalNotes': approvalNotes,
        },
      );

      return ReturnRequest.fromJson(response.data['returnRequest']);
    } catch (e) {
      throw Exception('Error al aprobar devolución: $e');
    }
  }

  // Procesar devolución
  Future<Map<String, dynamic>> processReturnAndRefund({
    required String returnRequestId,
    String? processNotes,
  }) async {
    try {
      final response = await dio.patch(
        '$baseUrl/returns/$returnRequestId/process',
        data: {
          'processNotes': processNotes,
        },
      );

      return {
        'returnRequest': ReturnRequest.fromJson(response.data['returnRequest']),
        'refundTransaction': response.data['refundTransaction'],
      };
    } catch (e) {
      throw Exception('Error al procesar reembolso: $e');
    }
  }

  // Rechazar solicitud
  Future<ReturnRequest> rejectReturnRequest({
    required String returnRequestId,
    required String rejectionReason,
    String? internalNotes,
  }) async {
    try {
      final response = await dio.patch(
        '$baseUrl/returns/$returnRequestId/reject',
        data: {
          'rejectionReason': rejectionReason,
          'internalNotes': internalNotes,
        },
      );

      return ReturnRequest.fromJson(response.data['returnRequest']);
    } catch (e) {
      throw Exception('Error al rechazar devolución: $e');
    }
  }

  // Obtener reporte de auditoría
  Future<Map<String, dynamic>> getAuditReport({
    required String storeId,
    String? actionType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = {
        'storeId': storeId,
        if (actionType != null) 'actionType': actionType,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response = await dio.get(
        '$baseUrl/returns/audit/report',
        queryParameters: queryParams,
      );

      return response.data;
    } catch (e) {
      throw Exception('Error al obtener reporte de auditoría: $e');
    }
  }
}
