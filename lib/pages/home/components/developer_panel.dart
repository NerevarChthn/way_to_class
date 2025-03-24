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
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Cache löschen'),
                onPressed: () async {
                  graph.clearCache();
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
    // Zeige Ladeanzeige
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Überprüfe Verschlüsselung..."),
                  ],
                ),
              ),
            ),
          ),
    );

    // Cache inspizieren und detaillierte Ergebnisse erhalten
    final inspectionResults = graph.inspectEncryptedCache();

    // Verschlüsselungstest durchführen
    final success = await SecurityManager.verifyEncryption();

    // Lade-Dialog schließen
    Navigator.pop(context);

    // Modernes Dialog-Design
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header mit Icon und Titel
                    Row(
                      children: [
                        Icon(
                          success
                              ? Icons.security
                              : Icons.security_update_warning,
                          color: success ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Verschlüsselungstest',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),

                    // Hauptinhalt
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Status der Verschlüsselung
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    success
                                        ? Colors.green[50]
                                        : Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    success ? Icons.check_circle : Icons.error,
                                    color: success ? Colors.green : Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    success
                                        ? "Verschlüsselung funktioniert"
                                        : "Verschlüsselungstest fehlgeschlagen",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          success
                                              ? Colors.green[800]
                                              : Colors.red[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Überschrift für die Details
                            const Text(
                              "Technische Details:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),

                            // Struktur-Cache Card
                            if (inspectionResults['hasStructureCache'] == true)
                              _buildEncryptionDetailsCard(
                                title: "Struktur-Cache",
                                entries: [
                                  "Größe: ${inspectionResults['structureCacheLength']} Bytes",
                                  "Format: ${inspectionResults['structureCacheFormat']}",
                                  if (inspectionResults['decryptionSuccess'] ==
                                      true)
                                    "Entschlüsselung: Erfolgreich",
                                  if (inspectionResults['jsonValid'] == true)
                                    "Einträge: ${inspectionResults['jsonEntryCount']}",
                                ],
                                icon: Icons.storage,
                                isExpanded: true,
                              ),

                            const SizedBox(height: 8),

                            // Zwei Cards nebeneinander mit Row und Expanded
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pfad-Cache Card
                                if (inspectionResults['hasPathCache'] == true)
                                  Expanded(
                                    child: _buildEncryptionDetailsCard(
                                      title: "Pfad-Cache",
                                      entries: [
                                        "Größe: ${inspectionResults['pathCacheLength']} Bytes",
                                        if (inspectionResults['pathDecryptionSuccess'] ==
                                            true)
                                          "Einträge: ${inspectionResults['pathEntryCount']}",
                                      ],
                                      icon: Icons.route,
                                    ),
                                  ),

                                // Trennabstand
                                if (inspectionResults['hasPathCache'] == true &&
                                    inspectionResults.containsKey('savedHits'))
                                  const SizedBox(width: 8),

                                // Cache-Statistik Card
                                if (inspectionResults.containsKey('savedHits'))
                                  Expanded(
                                    child: _buildEncryptionDetailsCard(
                                      title: "Cache-Statistik",
                                      entries: [
                                        "Hits: ${inspectionResults['savedHits']}",
                                        "Misses: ${inspectionResults['savedMisses']}",
                                      ],
                                      icon: Icons.query_stats,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(),

                    // Action Buttons
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Schließen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

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
    final results = graph.validateAllRoutes();

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
