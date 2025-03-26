import 'package:flutter/material.dart';

class RouteDescriptionPanel extends StatelessWidget {
  final String resultText;
  final List<String> instructions;
  final void Function()? onRefresh;

  const RouteDescriptionPanel({
    super.key,
    required this.resultText,
    required this.instructions,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasInstructions = instructions.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wegbeschreibung',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Wegbeschreibung neu generieren',
                    onPressed: onRefresh,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  hasInstructions
                      ? ListView.separated(
                        itemCount: instructions.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: theme.colorScheme.primary,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    instructions[index],
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                      : Center(
                        child: Text(
                          resultText,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
