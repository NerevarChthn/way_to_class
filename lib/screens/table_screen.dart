import 'package:flutter/material.dart';

class PersonsPage extends StatefulWidget {
  final List<Map<String, String>> persons;
  final Function(String)? onRoomSelected;

  const PersonsPage({super.key, required this.persons, this.onRoomSelected});

  @override
  State<PersonsPage> createState() => _PersonsPageState();
}

class _PersonsPageState extends State<PersonsPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filtere Personen basierend auf der Sucheingabe
    final filteredPersons =
        _searchQuery.isEmpty
            ? widget.persons
            : widget.persons.where((person) {
              final fullName =
                  '${person['name']} ${person['vorname']}'.toLowerCase();
              final room = _formatRoom(person['raum']).toLowerCase();
              final query = _searchQuery.toLowerCase();
              return fullName.contains(query) || room.contains(query);
            }).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.5),
            theme.colorScheme.surface,
          ],
        ),
      ),
      // Äußeres ListView als Scroll-Container
      child: ListView(
        children: [
          // Suchleiste
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Nach Name oder Raum suchen...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.primary,
                    ),
                    border: InputBorder.none,
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed:
                                  () => setState(() => _searchQuery = ''),
                            )
                            : null,
                  ),
                ),
              ),
            ),
          ),

          // Ergebnisanzahl
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '${filteredPersons.length} ${filteredPersons.length == 1 ? 'Person' : 'Personen'} gefunden',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tabellen-Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 65,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Name und Vorname',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 35,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Raum',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tabellen-Körper
          filteredPersons.isEmpty
              ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Keine Ergebnisse gefunden',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              )
              : ListView.builder(
                // Wichtig: inneres ListView als nicht-scrollender Bereich
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: filteredPersons.length,
                itemBuilder: (context, index) {
                  final person = filteredPersons[index];

                  // Abwechselnde Zeilenfarben
                  final isEvenRow = index % 2 == 0;
                  final rowColor =
                      isEvenRow
                          ? theme.colorScheme.surface
                          : theme.colorScheme.surface.withOpacity(0.5);

                  // Border-Radius für die letzte Zeile
                  final isLastItem = index == filteredPersons.length - 1;
                  final borderRadius =
                      isLastItem
                          ? const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          )
                          : null;

                  return Container(
                    decoration: BoxDecoration(
                      color: rowColor,
                      borderRadius: borderRadius,
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        childrenPadding: EdgeInsets.zero,
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              flex: 65,
                              child: Text(
                                '${person['name']}, ${person['vorname']}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 35,
                              child: Text(
                                _formatRoom(person['raum']),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.expand_more, size: 20),
                        children: [
                          Container(
                            color: theme.colorScheme.primaryContainer
                                .withOpacity(0.2),
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (person['position'] != null &&
                                    person['position']!.isNotEmpty)
                                  _buildDetailRow(
                                    context,
                                    Icons.work,
                                    'Funktion:',
                                    person['position']!,
                                  ),
                                if (person['telefon'] != null &&
                                    person['telefon']!.isNotEmpty)
                                  _buildDetailRow(
                                    context,
                                    Icons.phone,
                                    'Telefon:',
                                    person['telefon']!,
                                  ),
                                if (person['email'] != null &&
                                    person['email']!.isNotEmpty)
                                  _buildDetailRow(
                                    context,
                                    Icons.email,
                                    'E-Mail:',
                                    person['email']!,
                                  ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      final formattedRoom =
                                          _extractRoomForNavigation(
                                            person['raum'],
                                          );
                                      if (widget.onRoomSelected != null) {
                                        widget.onRoomSelected!(formattedRoom);
                                      }
                                    },
                                    icon: Icon(
                                      Icons.directions,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                    label: const Text('Zum Raum navigieren'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.secondary,
                                      foregroundColor:
                                          theme.colorScheme.onSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  String _formatRoom(String? room) {
    if (room == null) return '';
    return room.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _extractRoomForNavigation(String? roomInfo) {
    if (roomInfo == null || roomInfo.isEmpty) return '';

    // Extract building letter (e.g., "A" from "Haus A (Tinz) / 203")
    final buildingMatch = RegExp(r'Haus\s+([A-Za-z])').firstMatch(roomInfo);
    final buildingLetter = buildingMatch?.group(1) ?? '';

    // Extract room number (e.g., "203" from "Haus A (Tinz) / 203" or "A203" from "Haus A (Tinz) / A203")
    final roomMatch = RegExp(r'\/\s*(([A-Za-z])?\d+)').firstMatch(roomInfo);
    final roomNumberWithPossibleLetter = roomMatch?.group(1) ?? '';

    if (roomNumberWithPossibleLetter.isNotEmpty) {
      // Check if the room number already starts with a letter
      if (RegExp(r'^[A-Za-z]').hasMatch(roomNumberWithPossibleLetter)) {
        // Room number already contains the building letter, return as is
        return roomNumberWithPossibleLetter;
      } else if (buildingLetter.isNotEmpty) {
        // Room number doesn't have letter, but we found building letter, so combine them
        return buildingLetter + roomNumberWithPossibleLetter;
      }
    }

    return roomInfo; // Return original if parsing fails
  }
}
