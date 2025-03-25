import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:way_to_class/core/models/campus_graph.dart';
import 'package:way_to_class/service/campus_graph_service.dart';
import 'package:way_to_class/theme/manager.dart';
import 'package:way_to_class/core/utils/injection.dart';

class SettingsDropdown extends StatefulWidget {
  const SettingsDropdown({super.key});

  @override
  State<SettingsDropdown> createState() => _SettingsDropdownState();
}

class _SettingsDropdownState extends State<SettingsDropdown> {
  final GlobalKey _menuKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _backgroundEntry;
  final CampusGraphService _graphService = getIt<CampusGraphService>();
  bool _showDeveloperOptions = false;

  CampusGraph? get _currentGraph => _graphService.currentGraph;

  @override
  void initState() {
    super.initState();
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
                              children: [const SizedBox(height: 8)],
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
