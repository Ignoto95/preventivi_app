import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:html' as html; // Solo per Web
import 'api_client.dart';
import 'auth_service.dart';


class PdfService {
  static Future<void> generateAndOpenPdf(
      int idPreventivo, Map<String, dynamic> datiPreventivo) async {
    try {
      final isAdmin = await AuthService().isAdmin();
      if (!isAdmin) throw Exception('Accesso negato: solo admin');

      final response = await ApiClient().post(
        'generate-pdf/preventivo/$idPreventivo',
        body: jsonEncode(datiPreventivo),
        headers: {
          'Accept': 'application/pdf', // Specifica che vuoi ricevere un PDF
        },
      );

      if (response.statusCode == 200) {
        final pdfBytes = response.bodyBytes;
        final nome = datiPreventivo['nome_cliente']?.replaceAll(' ', '_') ?? 'Nome';
        final cognome = datiPreventivo['cognome_cliente']?.replaceAll(' ', '_') ?? 'Cognome';
        final fileName = 'Preventivo_${nome}_$cognome.pdf';

        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        
        html.Url.revokeObjectUrl(url);
      } else {
        throw Exception('Errore ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Errore generazione PDF: $e');
      throw Exception('Errore generazione PDF: $e');
    }
  }
}
