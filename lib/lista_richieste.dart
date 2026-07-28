import 'package:flutter/material.dart';
import 'dart:convert';
import 'services/api_client.dart';

class ListaRichiestePage extends StatefulWidget {
  @override
  _ListaRichiestePageState createState() => _ListaRichiestePageState();
}

class _ListaRichiestePageState extends State<ListaRichiestePage> {
  List<dynamic> _richieste = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRichieste();
  }

  Future<void> _loadRichieste() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().get('richieste-clienti?stato=in_attesa');
      if (response.statusCode == 200) {
        setState(() {
          _richieste = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di caricamento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Richieste Clienti'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRichieste,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _richieste.isEmpty
              ? Center(child: Text('Nessuna richiesta in attesa'))
              : ListView.builder(
                  itemCount: _richieste.length,
                  itemBuilder: (ctx, index) {
                    final richiesta = _richieste[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text('${richiesta['nome']} ${richiesta['cognome']}'),
                        subtitle: Text(richiesta['email']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approvaRichiesta(richiesta['id_richiesta']),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rifiutaRichiesta(richiesta['id_richiesta']),
                            ),
                          ],
                        ),
                        onTap: () => _showDettaglioRichiesta(richiesta),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _approvaRichiesta(int idRichiesta) async {
    try {
      final response = await ApiClient().post('richieste-clienti/$idRichiesta/approva');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cliente approvato (ID: ${data['id_cliente']})')),
        );
        await _loadRichieste();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  Future<void> _rifiutaRichiesta(int idRichiesta) async {
    // Implementa il rifiuto simile all'approvazione
  }

  void _showDettaglioRichiesta(Map<String, dynamic> richiesta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Dettaglio richiesta'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Nome', richiesta['nome']),
              _buildDetailRow('Cognome', richiesta['cognome']),
              _buildDetailRow('Email', richiesta['email']),
              _buildDetailRow('Telefono', richiesta['telefono']),
              _buildDetailRow('Indirizzo', richiesta['via']),
              _buildDetailRow('Città', richiesta['citta']),
              _buildDetailRow('Codice Fiscale', richiesta['codice_fiscale']),
              SizedBox(height: 10),
              Text('Data richiesta: ${richiesta['data_richiesta']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Chiudi'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value ?? 'N/A'),
          ],
        ),
      ),
    );
  }
}