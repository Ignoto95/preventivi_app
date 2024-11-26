import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Importa il file generato da flutterfire configure
import 'login_page.dart';
import 'home_page.dart';
import 'create_preventivo_page.dart';
import 'search_preventivo_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

    try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  // Inizializza Firebase con le opzioni generate
  //await Firebase.initializeApp(
  //  options: DefaultFirebaseOptions.currentPlatform, // Usa le opzioni di configurazione corrette
  //);

  runApp(MyApp());
  } catch (e) {
    print("Errore nell'inizializzazione di Firebase: $e");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preventivi App',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/create': (context) => CreatePreventivoPage(),
        '/search': (context) => SearchPreventivoPage(),
      },
    );
  }
}
