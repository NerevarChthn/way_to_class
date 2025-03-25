import 'package:flutter/material.dart';

class NodeAutocompleteField extends StatefulWidget {
  final List<String> nodeNames;
  final String hintText;
  final IconData prefixIcon;
  final String initialValue;
  final ValueChanged<String> onSelected;

  const NodeAutocompleteField({
    super.key,
    required this.nodeNames,
    required this.hintText,
    required this.prefixIcon,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<NodeAutocompleteField> createState() => _NodeAutocompleteFieldState();
}

class _NodeAutocompleteFieldState extends State<NodeAutocompleteField> {
  late TextEditingController _controller;

  /// Konvertiert Raumbezeichnungen, um numerische Teile ohne führende Nullen zu vergleichen
  String _normalizeRoomNumber(String input) {
    // Trennt die Eingabe in Buchstaben- und Zahlenblöcke
    final RegExp regex = RegExp(r'([a-zA-Z]+|\d+)');
    final matches = regex.allMatches(input);

    // Erstellt eine normalisierte Version der Eingabe
    final StringBuffer normalized = StringBuffer();

    for (final match in matches) {
      final part = match.group(0)!;

      // Wenn es eine Zahl ist, entferne führende Nullen
      if (RegExp(r'^\d+$').hasMatch(part)) {
        try {
          // Konvertiert zu int und zurück, um führende Nullen zu entfernen
          final normalizedNumber = int.parse(part).toString();
          normalized.write(normalizedNumber);
        } catch (e) {
          // Bei Fehler den Originaltext behalten
          normalized.write(part);
        }
      } else {
        // Buchstaben unverändert übernehmen
        normalized.write(part);
      }
    }

    return normalized.toString().toLowerCase();
  }

  /// Prüft, ob die Option mit der Abfrage übereinstimmt (mit spezieller Behandlung für Raumnummern)
  bool _matchesQuery(String option, String query) {
    // Überprüfen, ob die Abfrage mit einem Leerzeichen endet
    bool hasTrailingSpace = query.endsWith(' ');

    // Entferne Leerzeichen für die normalisierte Suche
    String trimmedQuery = query.trim();

    // Wenn die Abfrage leer ist, keine Übereinstimmung
    if (trimmedQuery.isEmpty) return false;

    final normalizedOption = _normalizeRoomNumber(option);
    final normalizedQuery = _normalizeRoomNumber(trimmedQuery);

    // Wenn die Abfrage mit einem Leerzeichen endet, prüfe auf vollständigen Teil
    if (hasTrailingSpace) {
      // Bei Leerzeichen: Suche nach "b11" als vollständiger Teil (nicht b114, b115, etc.)
      RegExp pattern = RegExp(
        normalizedQuery + r'(?!\d)',
      ); // Prüft, dass keine Zahl folgt
      return pattern.hasMatch(normalizedOption);
    }

    // Normale Suche: Option enthält die Abfrage
    return normalizedOption.contains(normalizedQuery);
  }

  /// Prüft, ob die Option mit der Abfrage beginnt (mit spezieller Behandlung für Raumnummern)
  bool _startsWithQuery(String option, String query) {
    // Entferne Leerzeichen für die normalisierte Suche
    String trimmedQuery = query.trim();

    final normalizedOption = _normalizeRoomNumber(option);
    final normalizedQuery = _normalizeRoomNumber(trimmedQuery);

    return normalizedOption.startsWith(normalizedQuery);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(NodeAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }

        final query = textEditingValue.text;
        List<String> matches =
            widget.nodeNames
                .where((option) => _matchesQuery(option, query))
                .toList();

        // Verbesserte Sortierung mit normalisierter Raumnummernlogik
        matches.sort((a, b) {
          // Wenn die Abfrage mit einem Leerzeichen endet, prüfen wir auf exakte Übereinstimmung
          if (query.endsWith(' ')) {
            bool aExact =
                _normalizeRoomNumber(a) == _normalizeRoomNumber(query.trim());
            bool bExact =
                _normalizeRoomNumber(b) == _normalizeRoomNumber(query.trim());

            if (aExact && !bExact) return -1;
            if (!aExact && bExact) return 1;
          }

          // Zuerst nach "beginnt mit" sortieren
          bool aStartsWith = _startsWithQuery(a, query);
          bool bStartsWith = _startsWithQuery(b, query);

          if (aStartsWith && !bStartsWith) return -1;
          if (!aStartsWith && bStartsWith) return 1;

          // Dann nach Länge (kürzere zuerst)
          return a.length - b.length;
        });

        return matches.take(10);
      },

      // Rest des Codes bleibt unverändert
      onSelected: (value) {
        _controller.text = value;
        widget.onSelected(value);
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // Update controller reference
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller.text != textController.text) {
            textController.text = _controller.text;
          }
        });

        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(widget.prefixIcon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      displayStringForOption: (option) => option,
    );
  }
}
