import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:preventivi_app/services/pdf_service.dart';
import 'create_preventivo_page.dart';
import 'ModificaPreventivoPage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> preventivi = [];
  String searchQuery = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPreventivi();
  }

  Future<void> fetchPreventivi() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://94.176.182.61:3000/preventivi'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          preventivi = data.map((item) => Map<String, dynamic>.from(item)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Errore durante il recupero dei preventivi');
      }
    } catch (e) {
      print('Errore: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredPreventivi = preventivi
        .where((preventivo) => preventivo["nome_cliente"].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Preventivi'),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'info',
                child: Text('Utente: ${currentUser?.email ?? "Sconosciuto"}'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreatePreventivoPage()),
                    );

                    if (result == true) {
                      fetchPreventivi();
                    }
                  },
                  icon: Icon(Icons.add),
                  label: Text('Nuovo Preventivo'),
                ),
              ],
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Cerca',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredPreventivi.isEmpty
                      ? Center(child: Text('Nessun preventivo trovato'))
                      : ListView.builder(
                          itemCount: filteredPreventivi.length,
                          itemBuilder: (context, index) {
                            final preventivo = filteredPreventivi[index];
                            List<dynamic> lavoriList = json.decode(json.encode(preventivo["lavori"] ?? []));

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 4.0,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Codice: ${preventivo["id_preventivo"]}',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('Cliente: ${preventivo["nome_cliente"]} ${preventivo["cognome_cliente"]}'),
                                    Text('Comune: ${preventivo["citta"]}'),
                                    Text('Indirizzo: ${preventivo["via"]}'),
                                    Text('Prezzo Totale: €${preventivo["prezzo_totale"]}'),
                                    SizedBox(height: 4),

                                    // Visualizzazione dei lavori
                                    lavoriList.isNotEmpty
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Lavori:', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ...lavoriList.map((lavoro) {
                                                return Text(
                                                  '- ${lavoro["tipo_lavoro"]}: ${lavoro["descrizione_lavoro"]} (€${lavoro["prezzo"]})',
                                                );
                                              }).toList(),
                                            ],
                                          )
                                        : Text('Lavori: Nessun lavoro'),

                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ModificaPreventivoPage(preventivo: preventivo),
                                              ),
                                            ).then((result) {
                                              if (result == true) {
                                                fetchPreventivi();
                                              }
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            // Eliminazione del preventivo
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text('Conferma eliminazione'),
                                                  content: Text('Sei sicuro di voler eliminare questo preventivo?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text('Annulla'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        setState(() {
                                                          preventivi.removeAt(index);
                                                        });

                                                        try {
                                                          final response = await http.delete(
                                                            Uri.parse('http://94.176.182.61:3000/preventivo/${preventivo["id_preventivo"]}'),
                                                          );

                                                          if (response.statusCode == 200) {
                                                            Navigator.pop(context);
                                                          } else {
                                                            throw Exception('Errore durante l\'eliminazione');
                                                          }
                                                        } catch (e) {
                                                          print('Errore: $e');
                                                          setState(() {
                                                            preventivi.insert(index, preventivo);
                                                          });
                                                          Navigator.pop(context);
                                                          showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return AlertDialog(
                                                                title: Text('Errore'),
                                                                content: Text('Non è stato possibile eliminare il preventivo. Riprova.'),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () {
                                                                      Navigator.pop(context);
                                                                    },
                                                                    child: Text('OK'),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        }
                                                      },
                                                      child: Text('Elimina'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.picture_as_pdf, color: Colors.green),
                                          onPressed: () {
                                            PDFService.generateAndDownloadPDF(preventivo);
                                          },
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
