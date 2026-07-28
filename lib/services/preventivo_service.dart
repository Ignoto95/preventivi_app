import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'api_client.dart';
import 'auth_service.dart';

class PreventivoService {
  Future<List<Map<String, dynamic>>> searchPreventivo(String query) async {
    final response = await ApiClient().get('clienti');

    if (response.statusCode != 200) {
      throw Exception('Errore ricerca preventivi: ${response.statusCode} - ${response.body}');
    }

    final List<dynamic> clienti = jsonDecode(response.body);
    final lowerQuery = query.toLowerCase();
    final results = <Map<String, dynamic>>[];

    for (final cliente in clienti) {
      final nomeCompleto = '${cliente['nome']} ${cliente['cognome']}'.toLowerCase();
      if (!nomeCompleto.contains(lowerQuery)) continue;

      final preventivi = cliente['preventivi'] as List<dynamic>? ?? [];
      for (final preventivo in preventivi) {
        results.add({
          'id_preventivo': preventivo['id_preventivo'],
          'name': '${cliente['nome']} ${cliente['cognome']}',
          'description': 'Preventivo del ${preventivo['data_preventivo']}',
          'amount': preventivo['prezzo_totale'],
        });
      }
    }

    return results;
  }

  Future<void> savePreventivo(Map<String, dynamic> preventivoData) async {
    try {
      // Verifica se l'utente è admin
      final isAdmin = await AuthService().isAdmin();
      if (!isAdmin) {
        throw Exception('Accesso negato: solo gli admin possono salvare preventivi');
      }

      final response = await ApiClient().post(
        'preventivo',
        body: jsonEncode(preventivoData),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Errore salvataggio preventivo: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Errore: ${e.toString()}');
    }
  }
}
