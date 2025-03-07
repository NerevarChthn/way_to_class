// Suchpanel für Start- und Zielauswahl
import 'package:flutter/material.dart';
import 'package:way_to_class/pages/graph_view_page.dart';
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
            Text('Start', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ziel', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      NodeAutocompleteField(
                        nodeNames: nodeNames,
                        hintText: 'Zielpunkt wählen',
                        prefixIcon: Icons.flag_outlined,
                        initialValue: zielValue,
                        onSelected: onZielChanged,
                      ),
                    ],
                  ),
                ),
                // Tausch-Button
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 8),
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
              icon: const Icon(Icons.directions),
              label: const Text('Weg finden'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
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

// Panel für Schnellzugriff-Funktionen
class QuickAccessPanel extends StatelessWidget {
  final VoidCallback onBathroomPressed;
  final VoidCallback onExitPressed;

  const QuickAccessPanel({
    super.key,
    required this.onBathroomPressed,
    required this.onExitPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schnellzugriff',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickAccessButton(
                  icon: Icons.wc,
                  label: 'Toilette',
                  onPressed: onBathroomPressed,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildQuickAccessButton(
                  icon: Icons.emergency,
                  label: 'Notausgang',
                  onPressed: onExitPressed,
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                _buildQuickAccessButton(
                  icon: Icons.map,
                  label: 'Karte',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GraphViewScreen(),
                      ),
                    );
                  },
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }
}
