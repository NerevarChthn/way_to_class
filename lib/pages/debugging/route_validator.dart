import 'dart:async';

import 'package:flutter/material.dart';
import 'package:way_to_class/constants/node_data.dart';
import 'package:way_to_class/service/campus_graph_service.dart';

class RouteValidatorScreen extends StatefulWidget {
  final CampusGraphService graphService;

  const RouteValidatorScreen({super.key, required this.graphService});

  @override
  State<RouteValidatorScreen> createState() => _RouteValidatorScreenState();
}

class _RouteValidatorScreenState extends State<RouteValidatorScreen> {
  bool _isRunning = false;
  bool _isComplete = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _results = [];
  int _totalRoutes = 0;
  int _testedRoutes = 0;
  int _failedRoutes = 0;
  int _maxRoutesToTest = 100;
  int _excludedNodes = 0;
  StreamSubscription? _validationSubscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _validationSubscription?.cancel();
    super.dispose();
  }

  void _startValidation() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _isComplete = false;
      _errorMessage = null;
      _results = [];
      _totalRoutes = 0;
      _testedRoutes = 0;
      _failedRoutes = 0;
      _excludedNodes = 0;
    });

    try {
      final stream = _validateRoutes(_maxRoutesToTest);
      _validationSubscription = stream.listen(
        (data) {
          setState(() {
            _totalRoutes = data['total'] ?? 0;
            _testedRoutes = data['tested'] ?? 0;
            _failedRoutes = data['failed'] ?? 0;
            _excludedNodes = data['excluded'] ?? 0;

            if (data['result'] != null) {
              _results.add(data['result']);
            }
          });
        },
        onDone: () {
          setState(() {
            _isRunning = false;
            _isComplete = true;
          });
        },
        onError: (error) {
          setState(() {
            _isRunning = false;
            _errorMessage = error.toString();
          });
        },
      );
    } catch (e) {
      setState(() {
        _isRunning = false;
        _errorMessage = e.toString();
      });
    }
  }

  bool _shouldIncludeNode(String nodeId) {
    switch (widget.graphService.currentGraph?.getNodeById(nodeId)?.type) {
      case nodeCorridor:
        return false;
      case nodeStaircase:
        return false;
      case nodeElevator:
        return false;
      default:
        return true;
    }
  }

  Stream<Map<String, dynamic>> _validateRoutes(int maxRoutes) async* {
    if (widget.graphService.currentGraph == null) {
      throw Exception('Graph nicht geladen');
    }

    final graph = widget.graphService.currentGraph!;
    final allNodeIds = graph.allNodeIds;
    final nodeIds = allNodeIds.where(_shouldIncludeNode).toList();
    final excludedCount = allNodeIds.length - nodeIds.length;
    final total = nodeIds.length * nodeIds.length;
    int tested = 0;
    int failed = 0;

    final limitedTotal = total > maxRoutes ? maxRoutes : total;

    for (int i = 0; i < nodeIds.length && tested < limitedTotal; i++) {
      final startId = nodeIds[i];

      for (int j = 0; j < nodeIds.length && tested < limitedTotal; j++) {
        if (i == j) continue;

        final targetId = nodeIds[j];
        tested++;

        try {
          final path = await _findPath(startId, targetId);

          if (path.isEmpty) {
            failed++;
            yield {
              'total': total,
              'tested': tested,
              'failed': failed,
              'excluded': excludedCount,
              'result': {
                'startId': startId,
                'targetId': targetId,
                'success': false,
                'error': 'Kein Pfad gefunden',
                'path': [],
              },
            };
          } else {
            yield {
              'total': total,
              'tested': tested,
              'failed': failed,
              'excluded': excludedCount,
              'result': {
                'startId': startId,
                'targetId': targetId,
                'success': true,
                'path': path,
              },
            };
          }
        } catch (e) {
          failed++;
          yield {
            'total': total,
            'tested': tested,
            'failed': failed,
            'excluded': excludedCount,
            'result': {
              'startId': startId,
              'targetId': targetId,
              'success': false,
              'error': e.toString(),
              'path': [],
            },
          };
        }

        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  Future<List<String>> _findPath(String startId, String targetId) async {
    try {
      final path = widget.graphService.getPath(startId, targetId);
      return path;
    } catch (e) {
      throw Exception('Fehler bei der Pfadberechnung: $e');
    }
  }

  void _stopValidation() {
    _validationSubscription?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _showDetailedResults() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteDetailDialog(results: _results),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(theme),
              const SizedBox(height: 24),
              _buildControls(theme),
              const SizedBox(height: 16),
              if (_errorMessage != null) _buildErrorBanner(theme),
              const SizedBox(height: 16),
              _buildProgressSection(theme),
              const SizedBox(height: 20),
              _buildResultsSummary(theme),
              const SizedBox(height: 16),
              if (_results.isNotEmpty) _buildViewDetailsButton(theme),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Routenvalidierung',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dieser Test validiert die Routenberechnung zwischen verschiedenen Knotenpunkten im Graph. '
              'Er überprüft, ob eine Route zwischen zwei zufälligen Punkten gefunden werden kann. '
              'Flure, Treppen und Aufzüge werden als Start-/Zielpunkte ausgeschlossen.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    final double nodesCount =
        widget.graphService.currentGraph?.allNodes
            .where(
              (n) =>
                  n.type != nodeCorridor &&
                  n.type != nodeStaircase &&
                  n.type != nodeElevator,
            )
            .length
            .toDouble() ??
        100;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Testeinstellungen',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxRoutesToTest.toDouble(),
                    min: 10,
                    max: nodesCount * nodesCount,
                    divisions: 99,
                    label: _maxRoutesToTest.toString(),
                    onChanged:
                        _isRunning
                            ? null
                            : (value) {
                              setState(() {
                                _maxRoutesToTest = value.toInt();
                              });
                            },
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$_maxRoutesToTest',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Maximale Anzahl zu testender Routen',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _startValidation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test starten'),
                  ),
                ),
                if (_isRunning) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _stopValidation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: theme.colorScheme.error,
                    ),
                    icon: const Icon(Icons.stop),
                    label: const Text('Abbrechen'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Ein unbekannter Fehler ist aufgetreten',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              (_isRunning || _isComplete)
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fortschritt',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _totalRoutes > 0 ? _testedRoutes / _totalRoutes : 0,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProgressStat(
                  theme,
                  'Getestet',
                  '$_testedRoutes',
                  theme.colorScheme.primary,
                ),
                _buildProgressStat(
                  theme,
                  'Fehlgeschlagen',
                  '$_failedRoutes',
                  theme.colorScheme.error,
                ),
                _buildProgressStat(
                  theme,
                  'Erfolgreich',
                  '${_testedRoutes - _failedRoutes}',
                  theme.colorScheme.tertiary,
                ),
              ],
            ),
            if (_excludedNodes > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Ausgeschlossen: $_excludedNodes Transitknoten (Flure, Treppen, Aufzüge)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSummary(ThemeData theme) {
    if (!_isComplete && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 40,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Starte den Test, um Ergebnisse zu sehen',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final successPercentage =
        _testedRoutes > 0
            ? ((_testedRoutes - _failedRoutes) / _testedRoutes * 100)
                .toStringAsFixed(1)
            : '0';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              _failedRoutes > 0
                  ? theme.colorScheme.error.withOpacity(0.3)
                  : theme.colorScheme.tertiary.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zusammenfassung',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _failedRoutes > 0 ? Icons.warning_amber : Icons.check_circle,
                  color:
                      _failedRoutes > 0
                          ? theme.colorScheme.error
                          : theme.colorScheme.tertiary,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Text(
                  '$successPercentage% Erfolgsquote',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        _failedRoutes > 0
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _failedRoutes > 0
                  ? '$_failedRoutes von $_testedRoutes Routen konnten nicht gefunden werden.'
                  : 'Alle $_testedRoutes getesteten Routen wurden erfolgreich gefunden!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewDetailsButton(ThemeData theme) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: _showDetailedResults,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: BorderSide(color: theme.colorScheme.primary),
        ),
        icon: const Icon(Icons.search),
        label: const Text('Details anzeigen'),
      ),
    );
  }

  Widget _buildProgressStat(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class RouteDetailDialog extends StatefulWidget {
  final List<Map<String, dynamic>> results;

  const RouteDetailDialog({super.key, required this.results});

  @override
  State<RouteDetailDialog> createState() => _RouteDetailDialogState();
}

class _RouteDetailDialogState extends State<RouteDetailDialog> {
  String _searchQuery = '';
  bool _showOnlyErrors = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredResults =
        widget.results.where((result) {
          if (_showOnlyErrors && (result['success'] ?? false)) {
            return false;
          }

          if (_searchQuery.isEmpty) {
            return true;
          }

          final startId = result['startId']?.toString().toLowerCase() ?? '';
          final targetId = result['targetId']?.toString().toLowerCase() ?? '';
          final error = result['error']?.toString().toLowerCase() ?? '';

          final query = _searchQuery.toLowerCase();

          return startId.contains(query) ||
              targetId.contains(query) ||
              error.contains(query);
        }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.5,
                          ),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Text(
                          'Detaillierte Ergebnisse (${filteredResults.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Nach Knoten suchen...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _showOnlyErrors,
                          onChanged: (value) {
                            setState(() {
                              _showOnlyErrors = value ?? false;
                            });
                          },
                        ),
                        const Text('Nur fehlerhafte Routen anzeigen'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    filteredResults.isEmpty
                        ? Center(
                          child: Text(
                            'Keine Ergebnisse gefunden',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        )
                        : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filteredResults.length,
                          itemBuilder: (context, index) {
                            final result = filteredResults[index];
                            final success = result['success'] ?? false;
                            final startId = result['startId'] ?? 'Unbekannt';
                            final targetId = result['targetId'] ?? 'Unbekannt';
                            final error = result['error'] as String?;
                            final path = result['path'] as List?;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color:
                                      success
                                          ? theme.colorScheme.tertiary
                                              .withOpacity(0.3)
                                          : theme.colorScheme.error.withOpacity(
                                            0.3,
                                          ),
                                ),
                              ),
                              child: ExpansionTile(
                                leading: Icon(
                                  success ? Icons.check_circle : Icons.error,
                                  color:
                                      success
                                          ? theme.colorScheme.tertiary
                                          : theme.colorScheme.error,
                                ),
                                title: Text(
                                  '$startId → $targetId',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle:
                                    success
                                        ? Text('${path?.length ?? 0} Knoten')
                                        : Text(
                                          error ?? 'Fehler bei der Berechnung',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.colorScheme.error,
                                              ),
                                        ),
                                children: [
                                  if (success &&
                                      path != null &&
                                      path.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pfad:',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                for (
                                                  int i = 0;
                                                  i < path.length;
                                                  i++
                                                )
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 4,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          '${i + 1}.',
                                                          style:
                                                              theme
                                                                  .textTheme
                                                                  .bodySmall,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          path[i].toString(),
                                                          style:
                                                              theme
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!success)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'Fehlerdetails: ${error ?? "Unbekannter Fehler"}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.error,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
