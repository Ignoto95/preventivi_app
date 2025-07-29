import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  static const String _backendUrl = 'http://94.176.182.61:3000/caldaie/invia-avviso';

  static Future<void> sendBoilerNotification({
    required String recipientEmail,
    required String boilerId,
    required String clientName,
  }) async {
    final response = await http.post(
      Uri.parse(_backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'recipientEmail': recipientEmail,
        'boilerId': boilerId,
        'clientName': clientName,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Errore sconosciuto');
    }
  }
}