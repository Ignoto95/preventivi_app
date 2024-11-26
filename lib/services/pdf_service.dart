import 'dart:typed_data';
import 'dart:html' as html;
// ignore: unused_import
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PDFService {
  // Funzione per generare e scaricare il PDF
  static Future<void> generateAndDownloadPDF(Map<String, dynamic> preventivo) async {
    try {
      // Crea un documento PDF
      final pdf = pw.Document();

      // Aggiungi una pagina con i dati del preventivo
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Dettagli Preventivo', style: pw.TextStyle(fontSize: 20)),
                pw.SizedBox(height: 20),
                pw.Text('Codice: ${preventivo['codice']}'),
                pw.Text('Ragione Sociale: ${preventivo['ragioneSociale']}'),
                pw.Text('Cliente: ${preventivo['cliente']}'),
                pw.Text('Fornitore: ${preventivo['fornitore']}'),
                pw.Text('Comune: ${preventivo['comune']}'),
                pw.Text('Indirizzo: ${preventivo['indirizzo']}'),
                pw.Text('Provincia: ${preventivo['provincia']}'),
                pw.Text('Partita IVA: ${preventivo['partitaIVA']}'),
              ],
            ),
          ),
        ),
      );

      // Converte il PDF in byte
      final pdfBytes = await pdf.save();

      // Scarica il PDF nel browser
      _downloadPDF(pdfBytes, 'preventivo_${preventivo['codice']}.pdf');
    } catch (e) {
      print('Errore durante la generazione del PDF: $e');
    }
  }

  // Funzione privata per scaricare il PDF nel browser
  static void _downloadPDF(Uint8List pdfBytes, String fileName) {
    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    // ignore: unused_local_variable
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = fileName
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
