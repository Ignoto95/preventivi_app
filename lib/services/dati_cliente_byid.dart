import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_service.dart';


Future<Map<String, dynamic>> fetchClienteById(int idCliente) async {
  try {
    // Verifica se l'utente è admin
    final isAdmin = await AuthService().isAdmin();
    if (!isAdmin) {
      throw Exception('Accesso negato: solo gli admin possono accedere ai dati clienti');
    }

    final response = await ApiClient().get('clienti/$idCliente');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Errore nel recupero dati cliente con id $idCliente: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Errore: ${e.toString()}');
  }
}