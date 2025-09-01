import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class ApiClient {
  final AuthService _authService = AuthService();
  final String baseUrl = 'https://imcimpianti.cloud/api';

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    return _sendRequest(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
    );
  }

  Future<http.Response> post(String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      headers: headers,
    );
  }

  Future<http.Response> put(String endpoint, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'PUT',
      endpoint: endpoint,
      body: body,
      headers: headers,
    );
  }

  Future<http.Response> delete(String endpoint, {
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
    );
  }

  Future<http.Response> _sendRequest({
    required String method,
    required String endpoint,
    Object? body,
    Map<String, String>? headers,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        await _authService.handleUnauthorized();
        throw Exception('Token non disponibile');
      }

      // Headers di base + headers aggiuntivi
      final allHeaders = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        ...?headers, // Spread operator per headers aggiuntivi
      };

      final uri = Uri.parse('$baseUrl/$endpoint');
      http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: allHeaders);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: allHeaders,
            body: body,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: allHeaders,
            body: body,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: allHeaders);
          break;
        default:
          throw Exception('Metodo HTTP non supportato: $method');
      }

      if (response.statusCode == 401) {
        await _authService.handleUnauthorized();
      }

      return response;
    } catch (e) {
      print('Errore nella richiesta $method a $endpoint: $e');
      rethrow;
    }
  }
  // In ApiClient
Future<String> buildFullUrl(String endpoint, {Map<String, String>? queryParams}) async {
  final token = await _authService.getToken();
  if (token == null) {
    await _authService.handleUnauthorized();
    throw Exception('Token non disponibile');
  }
  
  final uri = Uri.parse('$baseUrl/$endpoint');
  return uri.replace(queryParameters: {
    ...?uri.queryParameters,
    ...?queryParams,
    'token': token,
  }).toString();
}

Future<http.StreamedResponse> multipartRequest({
  required String method,
  required String endpoint,
  required List<http.MultipartFile> files,
  Map<String, String>? fields,
}) async {
  final token = await _authService.getToken();
  if (token == null) {
    await _authService.handleUnauthorized();
    throw Exception('Token non disponibile');
  }

  var request = http.MultipartRequest(method, Uri.parse('$baseUrl/$endpoint'));
  request.headers['Authorization'] = 'Bearer $token';
  
  if (fields != null) {
    request.fields.addAll(fields);
  }
  
  request.files.addAll(files);

  return await request.send();
}
 Future<http.Response> uploadMultipart(
    String endpoint,
    List<int> fileBytes,
    String fileName, {
    required String fieldName,
    Map<String, String> fields = const {},
  }) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('Token non disponibile');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/$endpoint'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    
    // Aggiungi campi
    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    // Aggiungi file
    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      fileBytes,
      filename: fileName,
    ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    return http.Response(responseBody, response.statusCode);
  }
}