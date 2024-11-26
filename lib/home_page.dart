import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:preventivi_app/services/pdf_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> preventivi = [
    {
      "codice": "A0001",
      "ragioneSociale": "Azienda 1",
      "cliente": "Sì",
      "fornitore": "No",
      "comune": "Milano",
      "indirizzo": "Via Roma 1",
      "provincia": "MI",
      "partitaIVA": "12345678901"
    },
    {
      "codice": "A0002",
      "ragioneSociale": "Azienda 2",
      "cliente": "No",
      "fornitore": "Sì",
      "comune": "Roma",
      "indirizzo": "Via Milano 20",
      "provincia": "RM",
      "partitaIVA": "98765432109"
    },
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // Filtra i dati in base alla query di ricerca
    List<Map<String, dynamic>> filteredPreventivi = preventivi
        .where((preventivo) => preventivo["ragioneSociale"]
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

    // Ottieni l'utente attualmente loggato
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Preventivi'),
        actions: [
          // Pulsante utente con menu per Logout
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
            // Pulsante "Nuova Scheda Preventivo" sopra la barra di ricerca
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/create');
                  },
                  icon: Icon(Icons.add),
                  label: Text('Nuovo Preventivo'),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Barra di ricerca
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
            // Tabella dati
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Codice')),
                    DataColumn(label: Text('Ragione Sociale')),
                    DataColumn(label: Text('Cliente')),
                    DataColumn(label: Text('Fornitore')),
                    DataColumn(label: Text('Comune')),
                    DataColumn(label: Text('Indirizzo')),
                    DataColumn(label: Text('Provincia')),
                    DataColumn(label: Text('Partita IVA')),
                    DataColumn(label: Text('Azioni')),
                  ],
                  rows: filteredPreventivi.map((preventivo) {
                    return DataRow(cells: [
                      DataCell(Text(preventivo["codice"])),
                      DataCell(Text(preventivo["ragioneSociale"])),
                      DataCell(Text(preventivo["cliente"])),
                      DataCell(Text(preventivo["fornitore"])),
                      DataCell(Text(preventivo["comune"])),
                      DataCell(Text(preventivo["indirizzo"])),
                      DataCell(Text(preventivo["provincia"])),
                      DataCell(Text(preventivo["partitaIVA"])),
                      DataCell(Row(
                       children: [
                         IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                         onPressed: () {
                         // Vai alla pagina di modifica
                          },
                          ),
                        IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                          // Elimina preventivo
                                setState(() {
                                preventivi.remove(preventivo);
                            });
                              },
                                ),
                        IconButton(
                           icon: Icon(Icons.picture_as_pdf, color: Colors.green),
                              onPressed: () {
                            PDFService.generateAndDownloadPDF(preventivo); // Usa il servizio PDF
                               },
                             ),
                              ],
                          )),
                        ]);
                    }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
