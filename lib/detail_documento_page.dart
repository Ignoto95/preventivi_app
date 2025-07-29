import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'services/pdf_documenti_service.dart';
import 'modifica_documenti_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DettaglioDocumentoPage extends StatefulWidget {
  final Map<String, dynamic> documento;

  const DettaglioDocumentoPage({Key? key, required this.documento}) : super(key: key);

  @override
  _DettaglioDocumentoPageState createState() => _DettaglioDocumentoPageState();
}

class _DettaglioDocumentoPageState extends State<DettaglioDocumentoPage> {
  final Map<String, String> _allegatoToBackendType = {
    'Modulo A12': 'modulo_a12',
    'Relazione Materiali': 'relazione_materiali',
    'Relazione Verifica': 'relazione_verifica',
  };

  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _checkAllegati();
  }

  Future<void> _checkAllegati() async {
    setState(() => _isLoading = true);
    try {
      final tipoDocumento = _getTipoDocumentoBackend();
      final response = await http.get(
        Uri.parse('http://94.176.182.61:3000/$tipoDocumento/${widget.documento["id_documento"]}/allegati'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          widget.documento['has_modulo_a12'] = data['has_modulo_a12'] ?? false;
          widget.documento['has_relazione_materiali'] = data['has_relazione_materiali'] ?? false;
          widget.documento['has_relazione_verifica'] = data['has_relazione_verifica'] ?? false;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Errore durante il recupero degli allegati: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getTipoDocumentoBackend() {
    switch(widget.documento["tipo_documento"].toLowerCase()) {
      case 'conformità': return 'conformita';
      case 'rispondenza': return 'rispondenza';
      default: return 'conformita';
    }
  }

  String _getAllegatoDisplayName(String tipoAllegato) {
    switch(tipoAllegato) {
      case 'modulo_a12': return 'Modulo A12';
      case 'relazione_materiali': return 'Relazione Materiali';
      case 'relazione_verifica': return 'Relazione di Verifica';
      default: return tipoAllegato;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Documento ${widget.documento["id_documento"]}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDocumentHeader(context),
                  const SizedBox(height: 24),
                  _buildAllegatiSection(context),
                ],
              ),
            ),
    );
  }

Widget _buildDocumentHeader(BuildContext context) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Documento di ${widget.documento["tipo_documento"]}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _modificaDocumento(context),
                    tooltip: 'Modifica documento',
                  ),
                  IconButton(
                    icon: Icon(Icons.picture_as_pdf, color: Colors.orange),
                    onPressed: () => _generaPdf(context),
                    tooltip: 'Genera PDF',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confermaEliminazione(context),
                    tooltip: 'Elimina documento',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoTile(
            icon: Icons.person,
            title: 'Cliente',
            value: '${widget.documento["nome_cliente"]} ${widget.documento["cognome_cliente"]}',
          ),
          _buildInfoTile(
            icon: Icons.calendar_today,
            title: 'Data',
            value: _formatData(widget.documento["data_documento"]),
          ),
          if (widget.documento["note"]?.isNotEmpty ?? false)
            _buildInfoTile(
              icon: Icons.note,
              title: 'Note',
              value: widget.documento["note"],
            ),
        ],
      ),
    ),
  );
}

  Widget _buildInfoTile({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllegatiSection(BuildContext context) {
    final allegati = [
      {
        'tipo': 'Modulo A12',
        'presente': widget.documento['has_modulo_a12'] ?? false,
        'icon': Icons.assignment,
        'color': Colors.blue,
      },
      {
        'tipo': 'Relazione Materiali',
        'presente': widget.documento['has_relazione_materiali'] ?? false,
        'icon': Icons.construction,
        'color': Colors.orange,
      },
      {
        'tipo': 'Relazione Verifica',
        'presente': widget.documento['has_relazione_verifica'] ?? false,
        'icon': Icons.verified,
        'color': Colors.green,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Allegati',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
          childAspectRatio: 1.5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: allegati.map((allegato) => _buildAllegatoCard(allegato, context)).toList(),
        ),
      ],
    );
  }

  Widget _buildAllegatoCard(Map<String, dynamic> allegato, BuildContext context) {
    final isPresente = allegato['presente'] as bool;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isPresente 
            ? () => _showAllegatoOptions(allegato['tipo'], context)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                allegato['icon'],
                size: 40,
                color: isPresente ? allegato['color'] : Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                allegato['tipo'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPresente ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              if (!isPresente)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Aggiungi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: allegato['color'],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showAddAllegatoDialog(allegato['tipo'], context),
                ),
              if (isPresente)
                Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: Icon(Icons.download, size: 20),
                      color: Colors.blue,
                      onPressed: () => _downloadModelloVuoto(allegato['tipo'], context),
                      tooltip: 'Scarica modello vuoto',
                    ),
                    IconButton(
                      icon: Icon(Icons.picture_as_pdf, size: 20),
                      color: Colors.red,
                      onPressed: () => _scaricaAllegato(allegato['tipo'], context),
                      tooltip: 'Scarica allegato',
                    ),
                    IconButton(
                      icon: Icon(Icons.upload, size: 20),
                      color: Colors.green,
                      onPressed: () => _uploadDocumentoCompilato(allegato['tipo'], context),
                      tooltip: 'Carica nuova versione',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      onPressed: () => _confermaEliminaAllegato(allegato['tipo'], context),
                      tooltip: 'Elimina allegato',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllegatoOptions(String tipoAllegato, BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text('Scarica modello vuoto'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadModelloVuoto(tipoAllegato, context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Scarica allegato'),
                onTap: () {
                  Navigator.pop(context);
                  _scaricaAllegato(tipoAllegato, context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload, color: Colors.green),
                title: const Text('Carica nuova versione'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadDocumentoCompilato(tipoAllegato, context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Elimina allegato'),
                onTap: () {
                  Navigator.pop(context);
                  _confermaEliminaAllegato(tipoAllegato, context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddAllegatoDialog(String tipoAllegato, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Aggiungi $tipoAllegato'),
          content: const Text('Come vuoi procedere?'),
          actions: [
            TextButton(
              child: const Text('Carica file esistente'),
              onPressed: () {
                Navigator.pop(context);
                _uploadDocumentoCompilato(tipoAllegato, context);
              },
            ),
            TextButton(
              child: const Text('Scarica modello vuoto'),
              onPressed: () {
                Navigator.pop(context);
                _downloadModelloVuoto(tipoAllegato, context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadModelloVuoto(String tipoAllegato, BuildContext context) async {
    try {
      final backendType = _allegatoToBackendType[tipoAllegato];
      if (backendType == null) throw Exception('Tipo allegato non supportato');

      final url = Uri.parse('http://94.176.182.61:3000/modello-vuoto/$backendType');
      if (!await launchUrl(url)) throw Exception('Impossibile avviare il download');
    } catch (e) {
      _showErrorSnackbar('Errore download: ${e.toString()}');
    }
  }

  Future<void> _uploadDocumentoCompilato(String tipoAllegato, BuildContext context) async {
    try {
      final backendType = _allegatoToBackendType[tipoAllegato];
      if (backendType == null) throw Exception('Tipo allegato non supportato');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isUploading = true);
        
        final file = result.files.first;
        final tipoDocumento = _getTipoDocumentoBackend();
        final url = Uri.parse('http://94.176.182.61:3000/$tipoDocumento/${widget.documento["id_documento"]}/upload');
        
        var request = http.MultipartRequest('POST', url);
        request.fields['tipo_allegato'] = backendType;
        
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'documento',
            file.bytes!,
            filename: file.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'documento',
            file.path!,
            filename: file.name,
          ));
        }

        final response = await request.send();
        
        if (response.statusCode == 200) {
          _showSuccessSnackbar('Documento caricato con successo!');
          await _checkAllegati(); // Refresh allegati
        } else {
          throw Exception('Errore durante il caricamento: ${response.statusCode}');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Errore: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _modificaDocumento(BuildContext context) async {
    final aggiornato = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ModificaDocumentiPage(
          documento: widget.documento,
          nome: widget.documento['nome_cliente'],
          cognome: widget.documento['cognome_cliente'],
          idCliente: widget.documento['id_cliente'],
        ),
      ),
    );
    if (aggiornato == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _generaPdf(BuildContext context) async {
    try {
      setState(() => _isLoading = true);
      await PdfDocumentoService.generateDocumentoPdf(widget.documento["id_documento"]);
      _showSuccessSnackbar('PDF generato con successo');
    } catch (e) {
      _showErrorSnackbar('Errore generazione PDF: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confermaEliminazione(BuildContext context) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Conferma eliminazione"),
        content: const Text("Eliminare definitivamente il DOCUMENTO e TUTTI gli ALLEGATI?"),
        actions: [
          TextButton(
            child: const Text("Annulla"), 
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Conferma"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    
    if (conferma == true) {
      try {
        setState(() => _isLoading = true);
        final tipoDoc = widget.documento["tipo_documento"].toString().toLowerCase();
        final tipo = tipoDoc.contains('conform') ? 'conformita' : 
                     tipoDoc.contains('rispondenza') ? 'rispondenza' : 
                     throw Exception('Tipo documento non supportato: $tipoDoc');
                
        final response = await http.delete(
          Uri.parse("http://94.176.182.61:3000/documenti/$tipo/${widget.documento["id_documento"]}"),
        );
        
        if (response.statusCode == 200 && mounted) {
          Navigator.pop(context, true);
          _showSuccessSnackbar('Documento eliminato con successo');
        } else {
          throw Exception('Errore ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        _showErrorSnackbar('Errore eliminazione: ${e.toString()}');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scaricaAllegato(String tipoAllegato, BuildContext context) async {
    try {
      final backendType = _allegatoToBackendType[tipoAllegato];
      if (backendType == null) throw Exception('Tipo allegato non supportato');

      final tipoDocumento = _getTipoDocumentoBackend();
      final url = Uri.parse('http://94.176.182.61:3000/$tipoDocumento/${widget.documento["id_documento"]}/download/$backendType');
      
      if (!await launchUrl(url)) throw Exception('Impossibile avviare il download');
    } catch (e) {
      _showErrorSnackbar('Errore download: ${e.toString()}');
    }
  }

  Future<void> _confermaEliminaAllegato(String tipoAllegato, BuildContext context) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Conferma eliminazione"),
        content: Text("Eliminare l'allegato ${_getAllegatoDisplayName(tipoAllegato)}?"),
        actions: [
          TextButton(
            child: const Text("Annulla"), 
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Conferma"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    
    if (conferma == true) {
      try {
        setState(() => _isLoading = true);
        final backendType = _allegatoToBackendType[tipoAllegato];
        if (backendType == null) throw Exception('Tipo allegato non supportato');

        final tipoDocumento = _getTipoDocumentoBackend();
        final url = Uri.parse('http://94.176.182.61:3000/$tipoDocumento/${widget.documento["id_documento"]}/delete-allegato/$backendType');
        
        final response = await http.delete(url);
        
        if (response.statusCode == 200) {
          _showSuccessSnackbar('${_getAllegatoDisplayName(tipoAllegato)} eliminato con successo');
          await _checkAllegati(); // Refresh allegati
        } else {
          throw Exception('Errore durante l\'eliminazione: ${response.statusCode}');
        }
      } catch (e) {
        _showErrorSnackbar('Errore durante l\'eliminazione: ${e.toString()}');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatData(dynamic rawDate) {
    if (rawDate == null) return 'N/A';
    final parsed = DateTime.tryParse(rawDate.toString());
    return parsed?.toIso8601String().substring(0, 10) ?? 'N/A';
  }
}