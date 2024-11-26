import 'dart:convert';
import 'package:http/http.dart' as http;

class PreventivoService {
  final String baseUrl = 'https://tuo-server.com/api'; // Sostituisci con il tuo URL

  // Metodo per salvare un nuovo preventivo
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

  // Metodo per cercare i preventivi
  Future<List<Map<String, dynamic>>> searchPreventivo(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/preventivo?search=$query'), // Endpoint con parametro di ricerca
    );

    if (response.statusCode != 200) {
      throw Exception('Errore durante la ricerca dei preventivi: ${response.body}');
    }

    // Decodifica e restituisci la lista dei risultati
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }
}
