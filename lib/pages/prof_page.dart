import 'package:flutter/material.dart';
import 'package:way_to_class/screens/table_screen.dart';
import 'package:way_to_class/service/html/html_find.dart'; // fetchHtml()
import 'package:way_to_class/service/html/html_parse.dart'; // parseHtml()

class ProfTablePage extends StatefulWidget {
  final Function(String)? onRoomSelected;

  const ProfTablePage({super.key, this.onRoomSelected});

  @override
  ProfTablePageState createState() => ProfTablePageState();
}

class ProfTablePageState extends State<ProfTablePage> {
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

  // External API to select a room from code
  void selectRoom(String roomCode) {
    if (widget.onRoomSelected != null) {
      widget.onRoomSelected!(roomCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: personsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Keine Daten gefunden.'));
        } else {
          return PersonsPage(
            persons: snapshot.data!,
            onRoomSelected: widget.onRoomSelected,
          );
        }
      },
    );
  }
}
