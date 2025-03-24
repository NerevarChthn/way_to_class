import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:way_to_class/constants/other.dart';
import 'package:way_to_class/core/models/campus_graph.dart';
import 'package:way_to_class/core/models/route_segments.dart';
import 'package:way_to_class/core/utils/injection.dart';
import 'package:way_to_class/pages/floors.dart';
import 'package:way_to_class/pages/graph_view_page.dart' show GraphViewScreen;
import 'package:way_to_class/pages/home/components/nav_bar.dart';
import 'package:way_to_class/pages/home/components/quick_access_panel.dart';
import 'package:way_to_class/pages/home/components/route_desc_panel.dart';
import 'package:way_to_class/pages/home/components/search_panel.dart';
import 'package:way_to_class/pages/prof_page.dart';
import 'package:way_to_class/screens/settings_dropdown.dart';
import 'package:way_to_class/service/campus_graph_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CampusGraphService _graphService = getIt<CampusGraphService>();
  late final Future<CampusGraph> _graphFuture;

  // State-Variablen
  String resultText = noPathSelected;
  final List<String> pathInstructions = [];
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  String _startValue = '';
  String _zielValue = '';

  // Routing-State
  List<RouteSegment>? _currentRouteSegments;
  String? _lastStartId;
  String? _lastTargetId;

  @override
  void initState() {
    super.initState();
    _graphFuture = _loadGraph();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<CampusGraph> _loadGraph() async {
    return _graphService.loadGraph(assetPath);
  }

  /// Findet einen Weg zwischen Start und Ziel und bereitet Anweisungen vor
  Future<void> _findPathAndGenerateInstructions({
    required String startId,
    required String targetId,
    bool forceRecompute = false,
  }) async {
    if (startId.isEmpty || targetId.isEmpty) {
      setState(() {
        resultText = 'Bitte wähle Start und Ziel aus.';
      });
      return;
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Rufe bestehende Route ab oder berechne neu (mit Caching)
      if (_lastStartId != startId ||
          _lastTargetId != targetId ||
          _currentRouteSegments == null ||
          forceRecompute) {
        // Neue Route berechnen und cachen
        _currentRouteSegments = await _graphService.getRouteSegments(
          startId,
          targetId,
        );
        _lastStartId = startId;
        _lastTargetId = targetId;

        log(
          'Route neu berechnet: ${_currentRouteSegments?.length ?? 0} Segmente',
        );
      } else {
        log(
          'Verwende gecachte Route: ${_currentRouteSegments?.length ?? 0} Segmente',
        );
      }

      // Anweisungen aus den Segmenten generieren
      final instructions = _graphService.getInstructionsFromSegments(
        _currentRouteSegments!,
      );

      if (instructions.isEmpty) {
        setState(() => resultText = 'Kein Weg gefunden.');
        return;
      }

      // Ergebnisse aktualisieren
      setState(() {
        resultText = instructions.join('\n\n');
        pathInstructions.clear();
        pathInstructions.addAll(instructions);
      });

      final double totalTime = stopwatch.elapsedMicroseconds / 1000;
      log('Gesamtzeit für Wegfindung und Anweisungen: $totalTime ms');
    } catch (e) {
      log('Fehler bei der Wegfindung: $e');
      setState(() => resultText = 'Fehler bei der Wegfindung: $e');
    }
  }

  /// Hauptmethode für die Wegfindung von UI-Eingaben
  Future<void> _findPath() async {
    try {
      final String startId = _getStartNodeId();
      final String targetId = _getTargetNodeId();

      if (startId.isEmpty) {
        setState(() => resultText = 'Bitte wähle einen Startpunkt aus.');
        return;
      }

      if (targetId.isEmpty) {
        setState(() => resultText = 'Bitte wähle ein Ziel aus.');
        return;
      }

      await _findPathAndGenerateInstructions(
        startId: startId,
        targetId: targetId,
      );
    } catch (e) {
      setState(() => resultText = e.toString());
    }
  }

  /// Sucht die nächste Toilette und berechnet den Weg dorthin
  Future<void> _findNearestBathroom() async {
    try {
      final String startId = _getStartNodeId();

      if (startId.isEmpty) {
        setState(() => resultText = 'Bitte wähle einen Startpunkt aus.');
        return;
      }

      final String nearestBathroomId = await _graphService
          .findNearestPointOfInterest(startId, PointOfInterestType.toilet);

      if (nearestBathroomId.isEmpty) {
        setState(
          () => resultText = 'Leider konnte keine Toilette gefunden werden.',
        );
        return;
      }

      await _findPathAndGenerateInstructions(
        startId: startId,
        targetId: nearestBathroomId,
      );
    } catch (e) {
      setState(() => resultText = e.toString());
    }
  }

  /// Sucht den nächsten Notausgang und berechnet den Weg dorthin
  Future<void> _findNearestEmergencyExit() async {
    try {
      final String startId = _getStartNodeId();

      if (startId.isEmpty) {
        setState(() => resultText = 'Bitte wähle einen Startpunkt aus.');
        return;
      }

      final String nearestExitId = await _graphService
          .findNearestPointOfInterest(startId, PointOfInterestType.exit);

      if (nearestExitId.isEmpty) {
        setState(
          () => resultText = 'Leider konnte kein Notausgang gefunden werden.',
        );
        return;
      }

      await _findPathAndGenerateInstructions(
        startId: startId,
        targetId: nearestExitId,
      );
    } catch (e) {
      setState(() => resultText = e.toString());
    }
  }

  /// Sucht die Mensa und berechnet den Weg dorthin
  Future<void> _findCanteen() async {
    try {
      final String startId = _getStartNodeId();

      if (startId.isEmpty) {
        setState(() => resultText = 'Bitte wähle einen Startpunkt aus.');
        return;
      }

      final String canteenId = await _graphService.findNearestPointOfInterest(
        startId,
        PointOfInterestType.canteen,
      );

      if (canteenId.isEmpty) {
        setState(
          () => resultText = 'Leider konnte keine Mensa gefunden werden.',
        );
        return;
      }

      await _findPathAndGenerateInstructions(
        startId: startId,
        targetId: canteenId,
      );
    } catch (e) {
      setState(() => resultText = e.toString());
    }
  }

  String _getStartNodeId() {
    final CampusGraph graph = _graphService.currentGraph!;
    return graph.getNodeIdByName(_startValue) ?? '';
  }

  String _getTargetNodeId() {
    final CampusGraph graph = _graphService.currentGraph!;
    return graph.getNodeIdByName(_zielValue) ?? '';
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigator'),
        elevation: 0,
        actions: [const SettingsDropdown()],
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: [_buildNavigationPage(), FloorViewer(), ProfTablePage()],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildNavigationPage() {
    final theme = Theme.of(context);

    return FutureBuilder<CampusGraph>(
      future: _graphFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Graph wird geladen...', style: theme.textTheme.bodyLarge),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Fehler beim Laden des Graphen: ${snapshot.error}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          );
        }

        final graph = snapshot.data!;
        final List<String> nodeNames = graph.nodeNames;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Oberer Bereich: Start- und Zielauswahl
                SearchPanel(
                  nodeNames: nodeNames,
                  startValue: _startValue,
                  zielValue: _zielValue,
                  onStartChanged:
                      (value) => setState(() => _startValue = value),
                  onZielChanged: (value) => setState(() => _zielValue = value),
                  onSwap:
                      () => setState(() {
                        final tempStart = _startValue;
                        _startValue = _zielValue;
                        _zielValue = tempStart;
                      }),
                  onFindPath: _findPath,
                ),

                const SizedBox(height: 16),

                // Wegbeschreibung
                Expanded(
                  child: RouteDescriptionPanel(
                    resultText: resultText,
                    instructions: pathInstructions,
                    onRefresh:
                        _currentRouteSegments != null
                            ? () async {
                              if (_lastStartId != null &&
                                  _lastTargetId != null) {
                                await _findPathAndGenerateInstructions(
                                  startId: _lastStartId!,
                                  targetId: _lastTargetId!,
                                  forceRecompute: true,
                                );
                              }
                            }
                            : null,
                  ),
                ),

                // Schnellzugriff-Panel
                QuickAccessPanel(
                  onBathroomPressed: _findNearestBathroom,
                  onExitPressed: _findNearestEmergencyExit,
                  onCanteenPressed: _findCanteen,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Definition für POI-Typen
enum PointOfInterestType { toilet, exit, canteen }
