import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'modifica_preventivo_page.dart';
import 'create_preventivo_page.dart' as createCompleto;
import 'create_preventivo_from_cliente_page.dart' as createDaCliente;
//import 'package:url_launcher/url_launcher.dart';
//import 'package:path_provider/path_provider.dart';
//import 'package:open_file/open_file.dart';
//import 'dart:io';
import 'services/pdf_service.dart';
import 'services/delete_preventivo.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, List<Map<String, dynamic>>> clientiConPreventivi = {};
  String searchQuery = "";
  String? filtroAnno;
  String? filtroMese;
  String? filtroGiorno;
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

        Map<String, List<Map<String, dynamic>>> clienti = {};

        for (var item in data) {
          final clienteKey = "${item["nome_cliente"]} ${item["cognome_cliente"]}";

          if (!clienti.containsKey(clienteKey)) {
            clienti[clienteKey] = [];
          }

          clienti[clienteKey]!.add(item);
        }

        setState(() {
          clientiConPreventivi = clienti;
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
    User? currentUser = FirebaseAuth.instance.currentUser;
  Widget _buildFiltroDataSheet() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Filtra per Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(labelText: 'Anno (es. 2025)'),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  filtroAnno = val.isNotEmpty ? val : null;
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(labelText: 'Mese (es. 05)'),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  filtroMese = val.isNotEmpty ? val : null;
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(labelText: 'Giorno (es. 14)'),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  filtroGiorno = val.isNotEmpty ? val : null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          icon: Icon(Icons.check),
          label: Text('Applica filtro'),
          onPressed: () {
            setState(() {});
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}
    return Scaffold(
      appBar: AppBar(
        title: Text('Clienti & Preventivi'),
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
                      MaterialPageRoute(builder: (context) => createCompleto.CreatePreventivoPage()),
                    );
                    if (result == true) fetchPreventivi();
                  },
                  icon: Icon(Icons.add),
                  label: Text('Nuovo Cliente/Preventivo'),
                ),
              ],
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Cerca Cliente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    icon: Icon(
                    Icons.filter_list,
                    color: (filtroAnno != null || filtroMese != null || filtroGiorno != null)
                        ? Colors.orange
                        : null,
                  ),
                  tooltip: 'Filtra per data',
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      builder: (context) => _buildFiltroDataSheet(),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.clear),
                  tooltip: 'Pulisci filtro',
                  onPressed: () {
                    setState(() {
                      filtroAnno = null;
                      filtroMese = null;
                      filtroGiorno = null;
                    });
                  },
                  ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : clientiConPreventivi.isEmpty
                      ? Center(child: Text('Nessun cliente trovato'))
                      : ListView(
                          children: clientiConPreventivi.entries
                              .where((entry) => entry.key.toLowerCase().contains(searchQuery.toLowerCase()))
                              .map((entry) {
                            final nomeCliente = entry.key;
                            final preventivi = entry.value;     
                            final preventiviFiltrati = preventivi.where((p) {
                              final data = DateTime.tryParse(p["data_preventivo"] ?? '') ?? DateTime.now();
                              final matchAnno = filtroAnno == null || data.year.toString() == filtroAnno;
                              final matchMese = filtroMese == null || data.month.toString().padLeft(2, '0') == filtroMese;
                              final matchGiorno = filtroGiorno == null || data.day.toString().padLeft(2, '0') == filtroGiorno;
                              return matchAnno && matchMese && matchGiorno;
                            }).toList();

                            if (preventiviFiltrati.isEmpty) return SizedBox.shrink(); // Nascondi se non ci sono preventivi dopo il filtro

                            final preventiviPerAnno = groupPreventiviByAnno(preventiviFiltrati);

                            return Card(
                              elevation: 3,
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              child: ExpansionTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(nomeCliente, style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.note_add, color: Colors.green),
                                      tooltip: 'Nuovo preventivo per $nomeCliente',
                                      onPressed: () async {
                                        final parts = nomeCliente.split(' ');
                                        final nome = parts.first;
                                        final cognome = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                                
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => createDaCliente.CreatePreventivoFromClientePage(
                                              nome: nome,
                                              cognome: cognome,
                                            ),
                                          ),
                                        );
                                        if (result == true) fetchPreventivi();
                                      },
                                    ),
                                  ],
                                ),
                                subtitle: Text(preventivi.first['email'] ?? ''),
                                children: preventiviPerAnno.entries.map((annoEntry) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 16.0, top: 8),
                                        child: Text('Anno ${annoEntry.key}',
                                            style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      ...annoEntry.value.map((preventivo) {
                                        return ListTile(
                                          title: Text('Preventivo #${preventivo["id_preventivo"]}'),
                                          subtitle: Text('Data: ${preventivo["data_preventivo"]}, Totale: €${preventivo["prezzo_totale"]}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                      IconButton(
                                        icon: Icon(Icons.picture_as_pdf, color: Colors.orange),
                                        tooltip: 'Genera PDF',
                                        onPressed: () async {
                                          try {
                                            // Passa l'id e TUTTI i dati del preventivo come mappa
                                            await PdfService.generateAndOpenPdf(preventivo["id_preventivo"], preventivo);
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('$e')),
                                            );
                                          }
                                        },
                                      ),
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ModificaPreventivoPage(preventivo: preventivo),
                                              ),
                                            );
                                            if (result == true) {
                                              fetchPreventivi();
                                            }
                                          },
                                        ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final deleted = await confermaECancellaPreventivo(context, preventivo["id_preventivo"]);
                                      
                                          if (deleted) {
                                            fetchPreventivi();
                                          }
                                        },
                                      ),
                                      ],
                                    ),
                                        );
                                      }).toList(),
                                    ],
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> groupPreventiviByAnno(List<Map<String, dynamic>> preventivi) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var preventivo in preventivi) {
      final date = DateTime.tryParse(preventivo["data_preventivo"] ?? '') ?? DateTime.now();
      final year = date.year.toString();

      if (!grouped.containsKey(year)) {
        grouped[year] = [];
      }
      grouped[year]!.add(preventivo);
    }

    return grouped;
  }
}
