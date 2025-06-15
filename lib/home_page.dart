import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
//import 'package:intl/intl.dart';
import 'services/pdf_preventivi_service.dart';
import 'services/pdf_documenti_service.dart';
import 'services/delete_preventivo.dart';
import 'dart:convert';
//import 'modifica_documenti.dart';
import 'modifica_documenti_page.dart';
import 'modifica_preventivo_page.dart';
//import 'documenti_model.dart';
import 'nuovo_cliente_page.dart.dart';
import 'create_preventivo_from_cliente_page.dart' as createDaCliente;
import 'create_documento_conformita_page.dart' as createDocumento;


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, List<Map<String, dynamic>>> clientiConPreventivi = {};
  Map<String, List<Map<String, dynamic>>> clientiConDocumenti = {};
  String searchQuery = "";
  String? filtroAnno;
  String? filtroMese;
  String? filtroGiorno;
  bool isLoading = true;
  

  @override
  void initState() {
    super.initState();
    fetchPreventivi().then((_) => fetchDocumenti());
  }

Future<void> fetchPreventivi() async {
  setState(() => isLoading = true);
  
  try {
    final response = await http.get(Uri.parse('http://94.176.182.61:3000/clienti'));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      Map<String, List<Map<String, dynamic>>> clienti = {};

      for (var cliente in data) {
        final clienteKey = "${cliente["nome"]} ${cliente["cognome"]}";
        final List<dynamic> preventivi = cliente["preventivi"] ?? [];
        
        // Creiamo una mappa tipizzata per le info del cliente
        final Map<String, dynamic> clienteInfo = {
          'nome': cliente["nome"],
          'cognome': cliente["cognome"],
          'citta': cliente["citta"],
          'via': cliente["via"],
          'email': cliente["email"],
          'telefono': cliente["telefono"],
          'codice_fiscale': cliente["codice_fiscale"],
          'id_cliente': cliente["id_cliente"],
          'has_preventivi': preventivi.isNotEmpty,
          'preventivi': preventivi.map<Map<String, dynamic>>((p) => {
            'id_preventivo': p["id_preventivo"],
            'data_preventivo': p["data_preventivo"],
            'prezzo_totale': p["prezzo_totale"],
            'nome_cliente': cliente["nome"],
            'cognome_cliente': cliente["cognome"],
            'email': cliente["email"],
            'id_cliente': cliente["id_cliente"],
            'telefono': cliente["telefono"],
            'citta': cliente["citta"],
            'via': cliente["via"],
            'codice_fiscale': cliente["codice_fiscale"],
            'lavori': p["lavori"] ?? [], // Aggiungi lavori
            'rate': p["rate"] ?? [],
            
          }).toList(),
        };

        clienti[clienteKey] = [clienteInfo];
      }

      setState(() {
        clientiConPreventivi = clienti;
        isLoading = false;
      });
    } else {
      throw Exception('Errore durante il recupero dei dati');
    }
  } catch (e) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Errore: ${e.toString()}')),
    );
  }
}


  Future<void> fetchDocumenti() async {
    try {
      final response = await http.get(Uri.parse('http://94.176.182.61:3000/documenti'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        Map<String, List<Map<String, dynamic>>> clienti = {};
        for (var item in data) {
          final clienteKey = "${item["nome_cliente"]} ${item["cognome_cliente"]}";
          clienti.putIfAbsent(clienteKey, () => []).add(item);
        }
        setState(() {
          clientiConDocumenti = clienti;
        });
      } else {
        throw Exception('Errore durante il recupero dei documenti');
      }
    } catch (e) {
      print('Errore documenti: $e');
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
      toolbarHeight: 80,
        title: Container(
          padding: EdgeInsets.only(left: 8),
          child: Image.asset(
             'assests/Logosimone.png',
              height: 90,
              fit: BoxFit.scaleDown,
               ),
  ),
   centerTitle: false,
   
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
FloatingActionButton(
  mini: true,
  onPressed: () async {
    final idCliente = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => NuovoClientePage()),
    );
    
    if (idCliente != null) {
      // Opzionale: mostra messaggio o aggiorna lista clienti
      //ScaffoldMessenger.of(context).showSnackBar(
      //  SnackBar(content: Text('Cliente creato con ID: $idCliente')),
      //);
      await fetchPreventivi();
      await fetchDocumenti();
      setState(() {}); // Aggiorna l'interfaccia
    }
  },
  child: Icon(Icons.person_add),
  tooltip: 'Nuovo Cliente',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.filter_list),
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
      : ListView(
          children: clientiConPreventivi.entries
              .where((entry) => entry.key.toLowerCase().contains(searchQuery.toLowerCase()))
              .map((entry) {
            final nomeCliente = entry.key;
            final clienteData = entry.value.first;
            final hasPreventivi = clienteData['has_preventivi'] ?? false;
            final preventivi = clienteData['preventivi'] ?? [];
            final documenti = clientiConDocumenti[nomeCliente] ?? [];
            final hasDocumenti = documenti.isNotEmpty;

            final preventiviFiltrati = hasPreventivi 
                ? preventivi.where((p) {
                    final data = DateTime.tryParse(p["data_preventivo"] ?? '') ?? DateTime.now();
                    final matchAnno = filtroAnno == null || data.year.toString() == filtroAnno;
                    final matchMese = filtroMese == null || data.month.toString().padLeft(2, '0') == filtroMese;
                    final matchGiorno = filtroGiorno == null || data.day.toString().padLeft(2, '0') == filtroGiorno;
                    return matchAnno && matchMese && matchGiorno;
                  }).toList()
                : [];

            return Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8.0),
              child: ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(nomeCliente, style: TextStyle(fontWeight: FontWeight.bold))),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        IconButton(
                          icon: Icon(Icons.description, color: Colors.purple),
                          tooltip: 'Nuovo documento per $nomeCliente',
                          onPressed: () async {
                            final parts = nomeCliente.split(' ');
                            final nome = parts.first;
                            final cognome = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => createDocumento.CreateDocumentoFromClientePage(
                                  idCliente: clienteData['id_cliente'],
                                  nome: nome,
                                  cognome: cognome,
                                ),
                              ),
                            );
                            if (result == true) fetchDocumenti();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                subtitle: Text(clienteData['email'] ?? ''),
                children: [
                  // Sezione preventivi (solo se esistono)
                  if (hasPreventivi && preventiviFiltrati.isNotEmpty) ...[
                    ...groupPreventiviByAnno(preventiviFiltrati).entries.expand((annoEntry) => [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 8),
                            child: Text('Anno ${annoEntry.key}', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ...annoEntry.value.map((preventivo) => ListTile(
                                title: Text('Preventivo Numero °${preventivo["id_preventivo"]}'),
                                subtitle: Text('Data: ${formatDataString(preventivo["data_preventivo"])}, Totale: €${preventivo["prezzo_totale"]}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.picture_as_pdf, color: Colors.orange),
                                      tooltip: 'Genera PDF',
                                      onPressed: () async {
                                        try {
                                          await PdfService.generateAndOpenPdf(
                                            preventivo["id_preventivo"],
                                            preventivo,
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () async {
                                        await Future.delayed(Duration(milliseconds: 400));
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ModificaPreventivoPage(
                                              preventivo: preventivo,
                                              nome: preventivo['nome_cliente'],
                                              cognome: preventivo['cognome_cliente'],
                                              idCliente: preventivo['id_cliente'], 
                                            ),
                                          ),
                                        );
                                        if (result == true) fetchPreventivi();
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final deleted = await confermaECancellaPreventivo(context, preventivo["id_preventivo"]);
                                        if (deleted) fetchPreventivi();
                                      },
                                    ),
                                  ],
                                ),
                              )),
                        ]),
                  ] else if (!hasPreventivi) ...[
                    ListTile(
                      title: Text('Nessun preventivo', style: TextStyle(color: Colors.grey)),
                      subtitle: Text('Clicca + per crearne uno', style: TextStyle(color: Colors.grey[400])),
                      leading: Icon(Icons.info_outline, color: Colors.grey),
                    ),
                  ],
                  
                  // Sezione documenti (se esistono)
                  if (hasDocumenti) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16),
                      child: Text('Documenti di conformità', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...documenti.map((doc) => ListTile(
                          title: Text('${doc["tipo_documento"] ?? ""}'),
                          subtitle: Text('Data: ${formatDataString(doc["data_documento"] ?? "N/A")}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.picture_as_pdf, color: Colors.orange),
                                tooltip: 'Genera PDF',
                                onPressed: () async {
                                  try {
                                    await PdfDocumentoService.generateDocumentoPdf(doc["id_documento"]);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () async {
                                  await Future.delayed(Duration(milliseconds: 400));
                                  bool? aggiornato = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ModificaDocumentiPage(
                                          documento: doc,
                                          nome: doc['nome_cliente'],       
                                          cognome: doc['cognome_cliente'], 
                                          idCliente: doc['id_cliente'],
                                      ),
                                    ),
                                  );
                                  if (aggiornato == true) fetchDocumenti();
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Elimina Documento',
                                onPressed: () async {
                                  final conferma = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("Conferma eliminazione"),
                                      content: Text("Eliminare definitivamente il documento?"),
                                      actions: [
                                        TextButton(child: Text("Annulla"), onPressed: () => Navigator.pop(context, false)),
                                        ElevatedButton(child: Text("Conferma"), onPressed: () => Navigator.pop(context, true)),
                                      ],
                                    ),
                                  );
                                  if (conferma == true) {
                                    try {
                                      final res = await http.delete(
                                        Uri.parse("http://94.176.182.61:3000/documenti-conformita/${doc["id_documento"]}"),
                                      );
                                      if (res.statusCode == 200) {
                                        await fetchDocumenti();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Documento eliminato con successo.'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Errore: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        )),
                  ]
                ],
              ),
            );
          }).toList(),
        ),
)
        ],
      ),
    ),
  );
}
String formatDataString(dynamic rawDate) {
  if (rawDate == null) return '';
  final parsed = DateTime.tryParse(rawDate.toString());
  if (parsed == null) return '';
  return parsed.toIso8601String().substring(0, 10);
}

  Map<String, List<Map<String, dynamic>>> groupPreventiviByAnno(List<Map<String, dynamic>> preventivi) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var preventivo in preventivi) {
      final date = DateTime.tryParse(preventivo["data_preventivo"] ?? '') ?? DateTime.now();
      final year = date.year.toString();
      grouped.putIfAbsent(year, () => []).add(preventivo);
    }
    return grouped;
  }
}
