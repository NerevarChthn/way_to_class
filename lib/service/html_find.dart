import 'package:http/http.dart' as http;

Future<String> fetchHtml() async {
  final response = await http.get(
    Uri.parse(
      'https://www.dhge.de/DHGE/Hochschule/Organisation-und-Kontakte/Personenverzeichnis.html',
    ),
  );

  if (response.statusCode == 200) {
    // -> Daten sind enthalten, alles OK
    return response.body;
  } else {
    throw Exception('Fehler beim Laden der Seite');
  }
}
