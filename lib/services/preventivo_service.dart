import 'dart:convert';
import 'package:http/http.dart' as http;

class PreventivoService {
  final String baseUrl = 'http://94.176.182.61:3000'; // Modifica con il tuo IP/URL

  Future<void> savePreventivo(Map<String, dynamic> preventivoData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/preventivo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(preventivoData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Errore durante il salvataggio del preventivo: ${response.body}');
    }
  }
}
