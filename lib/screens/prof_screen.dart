import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html;

class HtmlTableScreen extends StatelessWidget {
  final String htmlContent = """
    <table>
      <tr><th>Raum</th><th>Kapazität</th><th>Etage</th></tr>
      <tr><td>E318</td><td>30</td><td>3</td></tr>
      <tr><td>E222</td><td>25</td><td>2</td></tr>
      <tr><td>C202</td><td>40</td><td>2</td></tr>
      <tr><td>D303</td><td>35</td><td>3</td></tr>
    </table>
  """;

  const HtmlTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final document = html.parse(htmlContent); // HTML parsen
    final rows = document.getElementsByTagName('tr'); // Alle Zeilen extrahieren

    // Header aus der ersten Zeile extrahieren
    final headerRow = rows.first.getElementsByTagName('th');
    final headers = headerRow.map((e) => e.text).toList();

    // Tabellen-Daten (außer Header)
    final tableData =
        rows.skip(1).map((row) {
          final columns = row.getElementsByTagName('td');
          return columns.map((e) => e.text).toList();
        }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('HTML Tabelle mit Klappfunktion')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: tableData.length,
          itemBuilder: (context, index) {
            final row = tableData[index];
            return ExpansionTile(
              title: Text(
                row[0],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kapazität: ${row[1]}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text('Etage: ${row[2]}', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
