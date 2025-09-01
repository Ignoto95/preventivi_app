import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';
import 'auth_service.dart';


class EmailService {
  static Future<void> sendBoilerNotification({
    required String recipientEmail,
    required String boilerId,
    required String clientName,
  }) async {
    try {
      // Verifica se l'utente è admin
      final isAdmin = await AuthService().isAdmin();
      if (!isAdmin) {
        throw Exception('Accesso negato: solo gli admin possono inviare notifiche');
      }

      final response = await ApiClient().post(
        'caldaie/invia-avviso',
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
    } catch (e) {
      throw Exception('Errore invio email: ${e.toString()}');
    }
  }
}