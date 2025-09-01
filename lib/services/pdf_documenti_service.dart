import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_service.dart';


class PdfDocumentoService {
  static Future<void> generateDocumentoPdf(
    int idDocumento, 
    String nomeCliente, 
    String cognomeCliente,
    String tipoDocumento,
  ) async {
    try {
      // Verifica se l'utente è admin
      final isAdmin = await AuthService().isAdmin();
      if (!isAdmin) {
        throw Exception('Accesso negato: solo gli admin possono generare documenti');
      }

      final response = await ApiClient().get('documenti/pdf/$idDocumento');

      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        final tipoNormalizzato = tipoDocumento.toLowerCase().contains('conform') 
            ? 'Conformita' 
            : 'Rispondenza';
        
        final fileName = '${tipoNormalizzato}_${nomeCliente}_$cognomeCliente.pdf';
        
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
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