// Panel für Entwickleroptionen
import 'dart:developer' show log;
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:way_to_class/core/components/graph.dart' show Graph;

class DeveloperPanel extends StatelessWidget {
  final Graph graph;

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
                icon: Icons.storage,
                label: 'Cache',
                onPressed: () => _showCacheInfo(context),
              ),
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

  // Cache-Info Dialog
  void _showCacheInfo(BuildContext context) async {
    final stats = graph.getCacheStats();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.storage, color: Colors.blue),
                SizedBox(width: 8),
                Text('Cache-Statistik'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCacheStatCard(
                    title: 'Routenstrukturen im Cache',
                    value: stats['routeStructureCacheSize'].toString(),
                    examples: stats['estructureExamples'] as List,
                  ),
                  const SizedBox(height: 8),
                  _buildCacheStatCard(
                    title: 'Pfade im Cache',
                    value: stats['pathCacheSize'].toString(),
                    examples: stats['pathExamples'] as List,
                  ),
                  const SizedBox(height: 8),
                  _buildCachePerformanceCard(stats),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.terminal),
                label: const Text('Cache loggen'),
                onPressed: () {
                  graph.printCache();
                  graph.analyzeAllCacheSegments('wc_b4-pc_b11');
                  log('\n----- IM VERGLEICH -----');
                  graph.analyzeAllCacheSegments('pc_b11-wc_b4');
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Cache löschen'),
                onPressed: () async {
                  await graph.clearCache();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache wurde erfolgreich gelöscht'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Schließen'),
              ),
            ],
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
  void _verifyEncryption(BuildContext context) async {
    // Implementierung aus dem Original-Code, aber als separater Dialog
    // ... (umfangreicher Dialog-Code)
  }

  // Routenvalidierung
  void _validateRoutes(BuildContext context) async {
    // Fortschritts-Dialog anzeigen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  'Validiere alle Routen...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dieser Vorgang kann einige Zeit dauern.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
    );

    // Test starten
    final results = await graph.validateAllRoutes();

    // Dialog schließen
    Navigator.pop(context);

    // Ergebnisdialog anzeigen
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text('Routenvalidierung'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zusammenfassung
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          results['successRate'] > 0.95
                              ? Colors.green[50]
                              : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              results['successRate'] > 0.95
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color:
                                  results['successRate'] > 0.95
                                      ? Colors.green
                                      : Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Erfolgsrate: ${(results['successRate'] * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    results['successRate'] > 0.95
                                        ? Colors.green[800]
                                        : Colors.orange[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Erfolgreiche Tests: ${results['successCount']}'),
                        Text(
                          'Fehlgeschlagene Tests: ${results['failureCount']}',
                        ),
                        Text('Übersprungen: ${results['skippedCount']}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detaillierte Statistik
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistik',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildStatRow(
                            'Getestete Verbindungen',
                            results['totalTests'].toString(),
                          ),
                          _buildStatRow(
                            'Durchschnittliche Zeit',
                            '${(results['averageTimePerRoute'] * 1000).toStringAsFixed(1)} ms',
                          ),
                          _buildStatRow(
                            'Gesamtdauer',
                            '${results['elapsedTime'].toStringAsFixed(2)} s',
                          ),
                          const Divider(),
                          _buildStatRow(
                            'Fehler "Kein Pfad gefunden"',
                            results['noPathCount'].toString(),
                            isHighlighted: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Fehleranzeige
                  if (results['failureCount'] > 0) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Fehler',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Anzahl fehlerhafter Routen: ${results['failureCount']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              height: 100,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(8),
                              child: ListView.builder(
                                itemCount: min(
                                  5,
                                  (results['errorPaths'] as List).length,
                                ),
                                itemBuilder:
                                    (context, index) => Text(
                                      '• ${(results['errorPaths'] as List)[index]}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                              ),
                            ),
                            if ((results['errorPaths'] as List).length > 5)
                              Text(
                                '... und ${(results['errorPaths'] as List).length - 5} weitere Fehler',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              // Button zum Anzeigen aller Fehler
              if ((results['errorPaths'] as List).isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('Alle Fehler anzeigen'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Fehlerdetails'),
                            content: SizedBox(
                              width: double.maxFinite,
                              height: 300,
                              child: ListView.separated(
                                itemCount:
                                    (results['errorMessages'] as List).length,
                                separatorBuilder:
                                    (context, index) => const Divider(),
                                itemBuilder:
                                    (context, index) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Text(
                                        (results['errorMessages']
                                            as List)[index],
                                      ),
                                    ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Schließen'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Schließen'),
              ),
            ],
          ),
    );
  }

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
