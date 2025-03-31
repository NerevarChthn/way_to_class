import 'package:flutter/material.dart';

class SettingsMenu extends StatelessWidget {
  final bool isDarkMode;
  final bool isCacheEnabled;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<bool> onCacheEnabledChanged;
  final VoidCallback onDeveloperOptionsPressed;

  const SettingsMenu({
    super.key,
    required this.isDarkMode,
    required this.isCacheEnabled,
    required this.onDarkModeChanged,
    required this.onCacheEnabledChanged,
    required this.onDeveloperOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings),
      tooltip: 'Einstellungen',
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: PopupMenuPosition.under,
      itemBuilder:
          (context) => [
            _buildPopupHeader(context, theme),
            const PopupMenuItem(enabled: false, height: 1, child: Divider()),
            _buildSwitchItem(
              icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
              title: 'Dunkles Design',
              subtitle: isDarkMode ? 'Aktiviert' : 'Deaktiviert',
              value: isDarkMode,
              onChanged: (value) {
                onDarkModeChanged(value);
                Navigator.pop(context);
              },
            ),
            _buildSwitchItem(
              icon: Icons.cached,
              title: 'Cache',
              subtitle: isCacheEnabled ? 'Aktiviert' : 'Deaktiviert',
              value: isCacheEnabled,
              onChanged: (value) {
                onCacheEnabledChanged(value);
                Navigator.pop(context);
              },
            ),
            const PopupMenuItem(enabled: false, height: 1, child: Divider()),
            PopupMenuItem<String>(
              value: 'developer',
              onTap: onDeveloperOptionsPressed,
              child: ListTile(
                leading: Icon(
                  Icons.developer_mode,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  'Entwickleroptionen',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
    );
  }

  PopupMenuItem<String> _buildPopupHeader(
    BuildContext context,
    ThemeData theme,
  ) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 42,
      child: Center(
        child: Text(
          'Einstellungen',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 64,
      child: StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: (newValue) {
                  setState(() {
                    onChanged(newValue);
                  });
                },
                activeColor: theme.colorScheme.primary,
              ),
            ],
          );
        },
      ),
    );
  }
}
