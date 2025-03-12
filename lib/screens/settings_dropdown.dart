import 'dart:developer' show log;
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:way_to_class/service/graph_service.dart';
import 'package:way_to_class/service/security/security_manager.dart';
import 'package:way_to_class/service/toast.dart';
import 'package:way_to_class/theme/manager.dart';
import 'package:way_to_class/core/utils/injection.dart';
import 'package:way_to_class/core/components/graph.dart' show Graph;

class SettingsDropdown extends StatefulWidget {
  const SettingsDropdown({super.key});

  @override
  State<SettingsDropdown> createState() => _SettingsDropdownState();
}

class _SettingsDropdownState extends State<SettingsDropdown> {
  final GlobalKey _menuKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _backgroundEntry;
  final GraphService _graphService = getIt<GraphService>();
  bool _cacheEnabled = true;
  bool _showDeveloperOptions = false;

  Graph? get _currentGraph => _graphService.currentGraph;

  @override
  void initState() {
    super.initState();
    _cacheEnabled = _graphService.cacheEnabled;
  }

  void _showSettingsMenu() {
    final RenderBox renderBox =
        _menuKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _backgroundEntry = OverlayEntry(
      builder:
          (context) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismissMenu,
            child: Container(
              color: Colors.transparent,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
    );

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: position.dy + size.height + 5,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 300,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF37474F),
                          ),
                          child: Text(
                            'Einstellungen',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildSettingTile(
                          title: 'Dark Mode',
                          icon: Icons.dark_mode,
                          value:
                              Provider.of<ThemeManager>(
                                context,
                                listen: false,
                              ).isDarkMode,
                          onChanged: (value) {
                            Provider.of<ThemeManager>(
                              context,
                              listen: false,
                            ).toggleTheme();
                            _updateOverlay();
                          },
                        ),
                        const Divider(height: 1, indent: 56, endIndent: 16),
                        _buildSettingTile(
                          title: 'Cache aktivieren',
                          icon: Icons.archive_outlined,
                          value: _cacheEnabled,
                          onChanged: (value) async {
                            setState(() => _cacheEnabled = value);
                            _graphService.setCacheEnabled(value);
                            Toast.successToast(
                              value ? 'Cache aktiviert' : 'Cache deaktiviert',
                            );
                            _updateOverlay();
                          },
                        ),
                        const Divider(height: 1, indent: 56, endIndent: 16),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFCFD8DC),
                            child: Icon(
                              Icons.cleaning_services,
                              color: const Color(0xFF546E7A),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Cache löschen',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF455A64),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              minimumSize: const Size(60, 36),
                            ),
                            onPressed: () async {
                              await _graphService.clearCache();
                              Toast.successToast('Cache wurde gelöscht');
                              _dismissMenu();
                            },
                            child: const Text('Löschen'),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFCFD8DC),
                            child: Icon(
                              Icons.developer_mode,
                              color: const Color(0xFF546E7A),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Entwickleroptionen',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          trailing: Icon(
                            _showDeveloperOptions
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: const Color(0xFF546E7A),
                          ),
                          onTap: () {
                            setState(
                              () =>
                                  _showDeveloperOptions =
                                      !_showDeveloperOptions,
                            );
                            _updateOverlay();
                          },
                        ),
                        if (_showDeveloperOptions && _currentGraph != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDeveloperButton(
                                  context,
                                  icon: Icons.storage,
                                  label: 'Cache-Stats',
                                  onPressed: () {
                                    _dismissMenu();
                                    _showCacheInfoDialog(context);
                                  },
                                ),
                                const SizedBox(height: 8),
                                _buildDeveloperButton(
                                  context,
                                  icon: Icons.security,
                                  label: 'Verschlüsselung',
                                  onPressed: () {
                                    _dismissMenu();
                                    _showEncryptionDialog(context);
                                  },
                                ),
                                const SizedBox(height: 8),
                                _buildDeveloperButton(
                                  context,
                                  icon: Icons.route,
                                  label: 'Routen validieren',
                                  onPressed: () {
                                    _dismissMenu();
                                    _validateRoutes(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_backgroundEntry!);
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildSettingTile({
    required String title,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: Switch(
        value: value,
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          return value
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.surfaceContainerHighest;
        }),
        thumbColor: WidgetStateProperty.all(
          value ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDeveloperButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF546E7A),
          side: BorderSide(color: const Color(0xFFCFD8DC)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showCacheInfoDialog(BuildContext context) async {
    if (_currentGraph == null) return;

    final stats = _currentGraph!.getCacheStats();
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
                    examples: stats['estructureExamples'] as List? ?? [],
                  ),
                  const SizedBox(height: 8),
                  _buildCacheStatCard(
                    title: 'Pfade im Cache',
                    value: stats['pathCacheSize'].toString(),
                    examples: stats['pathExamples'] as List? ?? [],
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
                  _currentGraph!.printCache();
                  _currentGraph!.analyzeAllCacheSegments('wc_b4-pc_b11');
                  log('\n----- IM VERGLEICH -----');
                  _currentGraph!.analyzeAllCacheSegments('pc_b11-wc_b4');
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Cache löschen'),
                onPressed: () async {
                  await _currentGraph!.clearCache();
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
      color:
          (stats['hitRate'] ?? 0.0) > 0.5
              ? Colors.green[50]
              : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  (stats['hitRate'] ?? 0.0) > 0.5
                      ? Icons.check_circle
                      : Icons.info,
                  color:
                      (stats['hitRate'] ?? 0.0) > 0.5
                          ? Colors.green
                          : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        (stats['hitRate'] ?? 0.0) > 0.5
                            ? Colors.green[800]
                            : Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cache-Hits: ${stats['hits'] ?? 0}'),
            Text('Cache-Misses: ${stats['misses'] ?? 0}'),
            const SizedBox(height: 4),
            Text(
              'Trefferquote: ${((stats['hitRate'] ?? 0.0) * 100).toStringAsFixed(2)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    (stats['hitRate'] ?? 0.0) > 0.5
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
  void _showEncryptionDialog(BuildContext context) async {
    if (_currentGraph == null) return;

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
    final inspectionResults = await _currentGraph!.inspectEncryptedCache();

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
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(entry, style: const TextStyle(fontSize: 12)),
              ),
            ),
            if (isExpanded && title == "Struktur-Cache")
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Der Struktur-Cache speichert strukturierte Wegbeschreibungen für häufig genutzte Routen.",
                  style: TextStyle(
                    fontSize: 11,
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

  void _validateRoutes(BuildContext context) async {
    if (_currentGraph == null) return;

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
    try {
      final results = await _currentGraph!.validateAllRoutes();

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
                            (results['successRate'] ?? 0.0) > 0.95
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
                                (results['successRate'] ?? 0.0) > 0.95
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color:
                                    (results['successRate'] ?? 0.0) > 0.95
                                        ? Colors.green
                                        : Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Erfolgsrate: ${((results['successRate'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      (results['successRate'] ?? 0.0) > 0.95
                                          ? Colors.green[800]
                                          : Colors.orange[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erfolgreiche Tests: ${results['successCount'] ?? 0}',
                          ),
                          Text(
                            'Fehlgeschlagene Tests: ${results['failureCount'] ?? 0}',
                          ),
                          Text('Übersprungen: ${results['skippedCount'] ?? 0}'),
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
                              results['totalTests']?.toString() ?? '0',
                            ),
                            _buildStatRow(
                              'Durchschnittliche Zeit',
                              '${((results['averageTimePerRoute'] ?? 0.0) * 1000).toStringAsFixed(1)} ms',
                            ),
                            _buildStatRow(
                              'Gesamtdauer',
                              '${(results['elapsedTime'] ?? 0.0).toStringAsFixed(2)} s',
                            ),
                            const Divider(),
                            _buildStatRow(
                              'Fehler "Kein Pfad gefunden"',
                              results['noPathCount']?.toString() ?? '0',
                              isHighlighted: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Fehleranzeige
                    if ((results['failureCount'] ?? 0) > 0) ...[
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
                                'Anzahl fehlerhafter Routen: ${results['failureCount'] ?? 0}',
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
                                    ((results['errorPaths'] as List?) ?? [])
                                        .length,
                                  ),
                                  itemBuilder:
                                      (context, index) => Text(
                                        '• ${((results['errorPaths'] as List?) ?? [])[index]}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                ),
                              ),
                              if (((results['errorPaths'] as List?) ?? [])
                                      .length >
                                  5)
                                Text(
                                  '... und ${((results['errorPaths'] as List?) ?? []).length - 5} weitere Fehler',
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
                if (((results['errorPaths'] as List?) ?? []).isNotEmpty)
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
                                      ((results['errorMessages'] as List?) ??
                                              [])
                                          .length,
                                  separatorBuilder:
                                      (context, index) => const Divider(),
                                  itemBuilder:
                                      (context, index) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Text(
                                          ((results['errorMessages']
                                                  as List?) ??
                                              [])[index],
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
    } catch (error) {
      // Dialog schließen
      Navigator.pop(context);

      // Fehlermeldung anzeigen
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Fehler'),
                ],
              ),
              content: Text(
                'Bei der Routenvalidierung ist ein Fehler aufgetreten: $error',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Schließen'),
                ),
              ],
            ),
      );
    }
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

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _dismissMenu();
      _showSettingsMenu();
    }
  }

  void _dismissMenu() {
    _overlayEntry?.remove();
    _backgroundEntry?.remove();
    _overlayEntry = null;
    _backgroundEntry = null;
  }

  @override
  void dispose() {
    _dismissMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: _menuKey,
      icon: const Icon(Icons.settings),
      onPressed: _showSettingsMenu,
    );
  }
}
