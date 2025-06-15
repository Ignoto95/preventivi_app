import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:html' as html; // Solo per Web

class PdfService {
  static Future<void> generateAndOpenPdf(
      int idPreventivo, Map<String, dynamic> datiPreventivo) async {
    final String url =
        'http://94.176.182.61:3000/generate-pdf/preventivo/$idPreventivo';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(datiPreventivo),
      );

      if (response.statusCode == 200) {
        final Uint8List pdfBytes = response.bodyBytes;

        final blob = html.Blob([pdfBytes], 'application/pdf');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);

        final nome = datiPreventivo['nome_cliente'] ?? 'Nome';
        final cognome = datiPreventivo['cognome_cliente'] ?? 'Cognome';
        final fileName = 'Preventivo.${nome}.${cognome}.pdf'
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'[^\w\.]'), '');

        final anchor = html.AnchorElement(href: blobUrl)
          ..setAttribute('download', fileName)
          ..click();

        html.Url.revokeObjectUrl(blobUrl);
      } else {
        final errorMessage =
            'Errore nella generazione del PDF: ${response.statusCode}';
        print(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Errore durante la richiesta PDF: $e';
      print(errorMessage);
      throw Exception(errorMessage);
    }
  }
}
