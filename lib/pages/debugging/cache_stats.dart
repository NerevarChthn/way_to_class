import 'package:flutter/material.dart';
import 'package:way_to_class/service/campus_graph_service.dart';

class CacheStatsScreen extends StatefulWidget {
  final CampusGraphService graphService;

  const CacheStatsScreen({super.key, required this.graphService});

  @override
  State<CacheStatsScreen> createState() => _CacheStatsScreenState();
}

class _CacheStatsScreenState extends State<CacheStatsScreen> {
  late Future<Map<String, dynamic>> _cacheFuture;

  @override
  void initState() {
    super.initState();
    _refreshCacheStats();
  }

  Future<void> _refreshCacheStats() async {
    setState(() {
      _cacheFuture = widget.graphService.getCacheStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _refreshCacheStats,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _cacheFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fehler beim Laden der Cache-Statistik',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Keine Cache-Daten verfügbar'));
            }

            final stats = snapshot.data!;
            final cacheEntries = stats['entries'] as List? ?? [];
            final hits = stats['hits'] as int? ?? 0;
            final misses = stats['misses'] as int? ?? 0;
            final totalSize = stats['size'] as int? ?? 0;

            return ListView(
              children: [
                _buildSummaryCard(theme, hits, misses, totalSize),
                const SizedBox(height: 16),
                Text(
                  'Cache-Einträge (${cacheEntries.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...cacheEntries.map(
                  (entry) => _buildCacheEntryCard(theme, entry),
                ),
                if (cacheEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'Keine Cache-Einträge vorhanden',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    int hits,
    int misses,
    int totalSize,
  ) {
    final hitRatio =
        hits + misses > 0
            ? (hits / (hits + misses) * 100).toStringAsFixed(1)
            : '0.0';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache-Übersicht',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.check_circle_outline,
                    'Treffer',
                    hits.toString(),
                    theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.highlight_off,
                    'Fehlschläge',
                    misses.toString(),
                    theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.percent,
                    'Trefferrate',
                    '$hitRatio%',
                    theme.colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.storage,
                    'Gesamtgröße',
                    '${(totalSize / 1024).toStringAsFixed(1)} KB',
                    theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            Center(
              child: TextButton.icon(
                onPressed: _refreshCacheStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Aktualisieren'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCacheEntryCard(ThemeData theme, Map<String, dynamic> entry) {
    final key = entry['key'] as String? ?? 'Unbekannt';
    final size = entry['size'] as int? ?? 0;
    final timestamp = entry['timestamp'] as int? ?? 0;
    final preview = entry['preview'] as String? ?? 'Keine Vorschau verfügbar';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(
          'Route: $key',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${(size / 1024).toStringAsFixed(2)} KB • ${_formatDate(date)}',
          style: theme.textTheme.bodySmall,
        ),
        leading: const Icon(Icons.route),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Vorschau:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              preview,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
