import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'api_client.dart';
import 'auth_service.dart';

class PreventivoService {
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
