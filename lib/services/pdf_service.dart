import 'dart:html' as html;
import 'package:http/http.dart' as http;

Future<void> downloadPdf(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final blob = html.Blob([response.bodyBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "preventivo.pdf")
        ..click();
      html.Url.revokeObjectUrl(url); // Libera l'oggetto URL
    } else {
      print('Errore nel download del PDF: ${response.statusCode}');
    }
  } catch (e) {
    print('Errore durante il download del PDF: $e');
  }
}
