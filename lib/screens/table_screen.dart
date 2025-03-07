import 'package:flutter/material.dart';

class PersonsPage extends StatefulWidget {
  final List<Map<String, String>> persons;

  const PersonsPage({super.key, required this.persons});

  @override
  State<PersonsPage> createState() => _PersonsPageState();
}

class _PersonsPageState extends State<PersonsPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter persons based on search query
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
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          // Search bar
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

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '${filteredPersons.length} ${filteredPersons.length == 1 ? 'Person' : 'Personen'} gefunden',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Table header
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

          // Table body
          Expanded(
            child:
                filteredPersons.isEmpty
                    ? Center(
                      child: Text(
                        'Keine Ergebnisse gefunden',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: filteredPersons.length,
                      itemBuilder: (context, index) {
                        final person = filteredPersons[index];

                        // Alternate row colors for better readability
                        final isEvenRow = index % 2 == 0;
                        final rowColor =
                            isEvenRow
                                ? theme.colorScheme.surface
                                : theme.colorScheme.surface.withValues(
                                  alpha: 0.5,
                                );

                        // Set border radius for last item
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
                            data: Theme.of(context).copyWith(
                              dividerColor:
                                  Colors
                                      .transparent, // Remove the expansion tile divider
                            ),
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
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
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
                              // Custom expansion icon
                              trailing: const Icon(Icons.expand_more, size: 20),
                              children: [
                                Container(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.2),
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                                      // Navigation button
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            // Navigate to this person's room
                                            Navigator.pop(
                                              context,
                                              _formatRoom(person['raum']),
                                            );
                                          },
                                          icon: const Icon(Icons.directions),
                                          label: const Text(
                                            'Zum Raum navigieren',
                                          ),
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

  // ungewollte Zeilenumbrüche und Leerzeichen entfernen (bei Raum)
  String _formatRoom(String? room) {
    if (room == null) return '';
    return room.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
