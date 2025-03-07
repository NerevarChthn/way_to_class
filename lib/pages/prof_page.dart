import 'package:flutter/material.dart';
import 'package:way_to_class/screens/table_screen.dart';
import 'package:way_to_class/service/html_find.dart'; // fetchHtml()
import 'package:way_to_class/service/html_parse.dart'; // parseHtml()

class ProfTablePage extends StatefulWidget {
  const ProfTablePage({super.key});

  @override
  State<ProfTablePage> createState() => _ProfTablePageState();
}

class _ProfTablePageState extends State<ProfTablePage> {
  late Future<List<Map<String, String>>> personsFuture;

  @override
  void initState() {
    super.initState();
    personsFuture = fetchAndParseHtml();
  }

  Future<List<Map<String, String>>> fetchAndParseHtml() async {
    String html = await fetchHtml(); // HTML abrufen
    return parseHtml(html); // HTML parsen
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: personsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // Ladeanzeige
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Fehler: ${snapshot.error}'),
          ); // Fehleranzeige
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('Keine Daten gefunden.'),
          ); // Leere Datenanzeige
        } else {
          return PersonsPage(persons: snapshot.data!); // Daten anzeigen
        }
      },
    );
  }
}
