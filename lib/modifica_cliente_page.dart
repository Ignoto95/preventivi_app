import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/api_client.dart';
import 'services/auth_service.dart';

class ModificaClientePage extends StatefulWidget {
  final Map<String, dynamic> cliente;

  const ModificaClientePage({Key? key, required this.cliente}) : super(key: key);

  @override
  _ModificaClientePageState createState() => _ModificaClientePageState();
}

class _ModificaClientePageState extends State<ModificaClientePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _cognomeController;
  late TextEditingController _cittaController;
  late TextEditingController _viaController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _codiceFiscaleController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.cliente['nome']);
    _cognomeController = TextEditingController(text: widget.cliente['cognome']);
    _cittaController = TextEditingController(text: widget.cliente['citta'] ?? '');
    _viaController = TextEditingController(text: widget.cliente['via']);
    _emailController = TextEditingController(text: widget.cliente['email'] ?? '');
    _telefonoController = TextEditingController(text: widget.cliente['telefono'] ?? '');
    _codiceFiscaleController = TextEditingController(text: widget.cliente['codice_fiscale'] ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _cittaController.dispose();
    _viaController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _codiceFiscaleController.dispose();
    super.dispose();
  }

Future<void> _salvaModifiche() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    // Verifica se l'utente è admin
    final isAdmin = await AuthService().isAdmin();
    if (!isAdmin) {
      throw Exception('Solo gli admin possono modificare i clienti');
    }

    final response = await ApiClient().put(
      'clienti/${widget.cliente['id_cliente']}',
      body: json.encode({
        'nome': _nomeController.text,
        'cognome': _cognomeController.text,
        'citta': _cittaController.text,
        'via': _viaController.text,
        'email': _emailController.text,
        'telefono': _telefonoController.text,
        'codice_fiscale': _codiceFiscaleController.text,
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente aggiornato con successo'),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, true);
      }
    } else {
      throw Exception('Errore durante l\'aggiornamento: ${response.body}');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modifica Cliente ${widget.cliente['nome']} ${widget.cliente['cognome']}',
          style: TextStyle(color: const Color.fromARGB(255, 80, 134, 195)),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _isLoading ? null : _salvaModifiche,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Informazioni Cliente',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.primaryColor,
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _nomeController,
                              decoration: InputDecoration(
                                labelText: 'Nome *',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? 'Campo obbligatorio' : null,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _cognomeController,
                              decoration: InputDecoration(
                                labelText: 'Cognome *',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? 'Campo obbligatorio' : null,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _viaController,
                              decoration: InputDecoration(
                                labelText: 'Via *',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? 'Campo obbligatorio' : null,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _cittaController,
                              decoration: InputDecoration(
                                labelText: 'Città',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value!.isNotEmpty && !value.contains('@')) {
                                  return 'Inserisci un\'email valida';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _telefonoController,
                              decoration: InputDecoration(
                                labelText: 'Telefono',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _codiceFiscaleController,
                              decoration: InputDecoration(
                                labelText: 'Codice Fiscale',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value!.isNotEmpty && value.length != 16) {
                                  return 'Il CF deve essere di 16 caratteri';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _salvaModifiche,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'SALVA MODIFICHE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}