import 'dart:html' as html;
import 'package:http/http.dart' as http;

class PdfDocumentoService {
  static Future<void> generateDocumentoPdf(int idDocumento) async {
    try {
      final response = await http.get(
        Uri.parse('http://94.176.182.61:3000/documenti/pdf/$idDocumento'),
      );

      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "documento_$idDocumento.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        throw Exception('Errore ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore generazione PDF: $e');
    }
  }
}