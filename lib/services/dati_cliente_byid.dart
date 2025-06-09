import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchClienteById(int idCliente) async {
  final url = Uri.parse('http://94.176.182.61:3000/clienti/$idCliente');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    // Assumiamo che il backend ritorni un JSON con i dati del cliente
    final Map<String, dynamic> clienteData = json.decode(response.body);
    return clienteData;
  } else {
    throw Exception('Errore nel recupero dati cliente con id $idCliente');
  }
}