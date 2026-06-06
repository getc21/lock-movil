import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class LocationProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  LocationProvider(this.token);

  Map<String, String> get _headers => <String, String>{
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Obtener todas las ubicaciones de una tienda
  Future<Map<String, dynamic>> getLocations({String? storeId}) async {
    try {
      final Map<String, String> queryParams = <String, String>{};
      if (storeId != null) queryParams['storeId'] = storeId;

      final Uri uri = Uri.parse('$baseUrl/locations').replace(queryParameters: queryParams);
      final http.Response response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final locations = data['data'];
        if (locations is List) {
          return <String, dynamic>{'success': true, 'data': locations};
        } else {
          return <String, dynamic>{'success': false, 'message': 'Formato de respuesta inválido'};
        }
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error obteniendo ubicaciones'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener ubicación por ID
  Future<Map<String, dynamic>> getLocationById(String id) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/locations/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return <String, dynamic>{'success': true, 'data': data['data']['location']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error obteniendo ubicación'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear ubicación
  Future<Map<String, dynamic>> createLocation({
    required String storeId,
    required String name,
    String? description,
  }) async {
    try {
      final http.Response response = await http.post(
        Uri.parse('$baseUrl/locations'),
        headers: _headers,
        body: jsonEncode(<String, String>{
          'storeId': storeId,
          'name': name,
          if (description != null) 'description': description,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return <String, dynamic>{'success': true, 'data': data['data']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error creando ubicación'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar ubicación
  Future<Map<String, dynamic>> updateLocation({
    required String id,
    String? name,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;

      final http.Response response = await http.patch(
        Uri.parse('$baseUrl/locations/$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return <String, dynamic>{'success': true, 'data': data['data']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error actualizando ubicación'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar ubicación
  Future<Map<String, dynamic>> deleteLocation(String id) async {
    try {
      final http.Response response = await http.delete(
        Uri.parse('$baseUrl/locations/$id'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return <String, dynamic>{'success': true};
      } else {
        final data = jsonDecode(response.body);
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error eliminando ubicación'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
