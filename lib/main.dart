import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Importa il file generato da flutterfire configure
import 'login_page.dart';
import 'home_page.dart';
import 'create_preventivo_page.dart';
import 'search_preventivo_page.dart';
import 'package:path_provider/path_provider.dart';
// import 'dart:io'; --> libreria non supportata lato web flutter
import 'package:flutter/foundation.dart'; // Import per kIsWeb
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

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

  Future<String> getTemporaryPath() async {
    if (kIsWeb) {
      // Per Web usa direttamente una stringa come percorso fittizio
      return '/web_temp/';
    } else {
      // Usa path_provider per le piattaforme mobili e desktop
      final directory = await getTemporaryDirectory();
      return directory.path;
    }
  }
}
