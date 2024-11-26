import 'package:flutter/material.dart';
import 'create_preventivo_page.dart';
import 'search_preventivo_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreatePreventivoPage()),
                );
              },
              child: Text('Crea nuovo preventivo'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchPreventivoPage()),
                );
              },
              child: Text('Cerca preventivo'),
            ),
          ],
        ),
      ),
    );
  }
}
