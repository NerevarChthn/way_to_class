// Panel für Entwickleroptionen
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:way_to_class/service/campus_graph_service.dart';
import 'package:way_to_class/service/security/security_manager.dart';

class DeveloperPanel extends StatelessWidget {
  final CampusGraphService graph;

  const DeveloperPanel({super.key, required this.graph});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Entwickleroptionen'),
      maintainState: true,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildDevButton(
                context,
                icon: Icons.security,
                label: 'Verschlüsselung',
                onPressed: () => _verifyEncryption(context),
              ),
              _buildDevButton(
                context,
                icon: Icons.route,
                label: 'Routen validieren',
                onPressed: () => _validateRoutes(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDevButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[700],
          side: BorderSide(color: Colors.grey[400]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Helper-Widgets für Cache-Info
  Widget _buildCacheStatCard({
    required String title,
    required String value,
    required List examples,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title: $value',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (examples.isNotEmpty)
              Text(
                'Beispiele: ${examples.join(", ")}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachePerformanceCard(Map<String, dynamic> stats) {
    return Card(
      margin: EdgeInsets.zero,
      color: stats['hitRate'] > 0.5 ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  stats['hitRate'] > 0.5 ? Icons.check_circle : Icons.info,
                  color: stats['hitRate'] > 0.5 ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        stats['hitRate'] > 0.5
                            ? Colors.green[800]
                            : Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cache-Hits: ${stats['hits']}'),
            Text('Cache-Misses: ${stats['misses']}'),
            const SizedBox(height: 4),
            Text(
              'Trefferquote: ${(stats['hitRate'] * 100).toStringAsFixed(2)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    stats['hitRate'] > 0.5
                        ? Colors.green[700]
                        : Colors.orange[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Verschlüsselungstest
  void _verifyEncryption(BuildContext context) async {}

  Widget _buildEncryptionDetailsCard({
    required String title,
    required List<String> entries,
    required IconData icon,
    bool isExpanded = false,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hier liegt der Überfluss - die Row braucht Flexibilität
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.blue[700]), // Kleinere Icons
                const SizedBox(width: 6), // Weniger Abstand
                Flexible(
                  // Hinzugefügt für Überfluss-Vermeidung
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      fontSize: 13, // Etwas kleinere Schrift
                    ),
                    overflow: TextOverflow.ellipsis, // Verhindert Überfluss
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  entry,
                  style: const TextStyle(fontSize: 12), // Kleinere Schriftgröße
                ),
              ),
            ),
            if (isExpanded && title == "Struktur-Cache")
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Der Struktur-Cache speichert strukturierte Wegbeschreibungen für häufig genutzte Routen.",
                  style: TextStyle(
                    fontSize: 11, // Noch kleinere Erklärungen
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Routenvalidierung
  void _validateRoutes(BuildContext context) async {}

  Widget _buildStatRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
