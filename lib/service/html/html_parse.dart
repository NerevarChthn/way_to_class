import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

List<Map<String, String>> parseHtml(String html) {
  Document document = html_parser.parse(html);
  List<Map<String, String>> persons = [];

  var rows = document.querySelectorAll('#event-teaser table tr');

  for (var row in rows.skip(1)) {
    // Erste Zeile (Header) überspringen
    final List<Element?> cells = row.querySelectorAll('td');

    if (cells.length >= 7) {
      // Mindestens 7 Spalten müssen vorhanden sein
      String campus =
          (cells[3]?.nodes.isNotEmpty ?? false)
              ? cells[3]?.nodes.last.text?.trim() ?? ''
              : '';

      if (campus.contains('Gera')) {
        persons.add({
          'name': cells[0]?.text.trim() ?? '',
          'vorname': cells[1]?.text.trim() ?? '',
          'position': cells[2]?.text.trim() ?? '',
          'campus': campus,
          'raum': cells[4]?.text.trim() ?? '',
          'telefon': cells[5]?.text.trim() ?? '',
          'email': cells[6]?.text.trim() ?? '',
        });
      }
    }
  }
  return persons;
}
