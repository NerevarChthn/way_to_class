import 'package:flutter/material.dart';

class QuickAccessPanel extends StatelessWidget {
  final VoidCallback onBathroomPressed;
  final VoidCallback onExitPressed;
  final VoidCallback onCanteenPressed;

  const QuickAccessPanel({
    super.key,
    required this.onBathroomPressed,
    required this.onExitPressed,
    required this.onCanteenPressed,
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
                  icon: Icons.restaurant,
                  label: 'Mensa',
                  onPressed: onCanteenPressed,
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
