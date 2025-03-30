// Suchpanel für Start- und Zielauswahl
import 'package:flutter/material.dart';
import 'package:way_to_class/pages/home/components/autocomplete_field.dart';

class SearchPanel extends StatelessWidget {
  final List<String> nodeNames;
  final String startValue;
  final String zielValue;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onZielChanged;
  final VoidCallback onSwap;
  final VoidCallback onFindPath;

  const SearchPanel({
    super.key,
    required this.nodeNames,
    required this.startValue,
    required this.zielValue,
    required this.onStartChanged,
    required this.onZielChanged,
    required this.onSwap,
    required this.onFindPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Startpunkt-Eingabe
            NodeAutocompleteField(
              nodeNames: nodeNames,
              hintText: 'Startpunkt wählen',
              prefixIcon: Icons.location_on_outlined,
              initialValue: startValue,
              onSelected: onStartChanged,
            ),

            const SizedBox(height: 16),

            // Zielpunkt-Eingabe mit Swap-Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NodeAutocompleteField(
                    nodeNames: nodeNames,
                    hintText: 'Zielpunkt wählen',
                    prefixIcon: Icons.flag_outlined,
                    initialValue: zielValue,
                    onSelected: onZielChanged,
                  ),
                ),
                // Tausch-Button
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: ElevatedButton(
                    onPressed: onSwap,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      elevation: 2,
                    ),
                    child: const Icon(Icons.swap_vert, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Weg finden Button
            ElevatedButton.icon(
              onPressed: onFindPath,
              icon: Icon(Icons.directions, color: theme.colorScheme.onPrimary),
              label: const Text('Weg finden'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
