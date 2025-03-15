// Panel für die Routenbeschreibung
import 'package:flutter/material.dart';
import 'package:way_to_class/constants/other.dart';

class RouteDescriptionPanel extends StatelessWidget {
  final String resultText;
  final Iterable<String> instructions;

  const RouteDescriptionPanel({
    super.key,
    required this.resultText,
    required this.instructions,
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
            Row(
              children: [
                const Icon(Icons.directions_walk),
                const SizedBox(width: 8),
                Text('Wegbeschreibung', style: theme.textTheme.titleMedium),
              ],
            ),
            const Divider(),
            Expanded(
              child:
                  resultText == noPathSelected
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions,
                              size: 48,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Wähle Start und Ziel, um einen Weg zu berechnen',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                instructions
                                    .map(
                                      (instruction) => RichText(
                                        text: TextSpan(
                                          children: [
                                            WidgetSpan(
                                              child: Icon(
                                                Icons.arrow_right,
                                                size: 16,
                                              ),
                                            ),
                                            TextSpan(
                                              text: instruction,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
