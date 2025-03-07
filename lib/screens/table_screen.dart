import 'package:flutter/material.dart';

class PersonsPage extends StatelessWidget {
  final List<Map<String, String>> persons;

  const PersonsPage({super.key, required this.persons});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Table(
              border: TableBorder.all(),
              columnWidths: {
                0: FixedColumnWidth(
                  0.6 * MediaQuery.of(context).size.width,
                ), // Name und Vorname in einer Spalte
                1: FixedColumnWidth(
                  0.35 * MediaQuery.of(context).size.width,
                ), // Raum
              },
              children: [
                // Header Row
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Name und Vorname',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Raum',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Data Rows
                for (var person in persons)
                  TableRow(
                    children: [
                      TableCell(
                        child: ExpansionTile(
                          title: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              '${person['name']} ${person['vorname']}',
                            ), // Name und Vorname kombiniert
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Funktion: ${person['position'] ?? ''}'),
                                  Text('Telefon: ${person['telefon'] ?? ''}'),
                                  Text('E-Mail: ${person['email'] ?? ''}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(_formatRoom(person['raum'])),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ungewollte Zeilenumbrüche und Leerzeichen entfernen (bei Raum)
  String _formatRoom(String? room) {
    if (room == null) return '';
    return room.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
