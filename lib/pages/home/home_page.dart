import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:way_to_class/pages/home/components/developer_panel.dart';
import 'package:way_to_class/pages/home/components/route_desc_panel.dart';
import 'package:way_to_class/pages/home/components/search_panel.dart';
import 'package:way_to_class/utils/load.dart' show loadAsset;
import 'package:way_to_class/core/components/graph.dart' show Graph;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Graph graph = Graph({});
  String resultText = 'Wegbeschreibung erscheint hier';
  String jsonCombined = '';

  // State-Variablen für die Werte der Eingabefelder
  String _startValue = '';
  String _zielValue = '';

  // Cache für Name-zu-ID-Zuordnung für bessere Performance
  final Map<String, String> _nameToIdCache = {};

  @override
  void initState() {
    super.initState();
    _loadAllGraphData();
  }

  Future<void> _loadAllGraphData() async {
    try {
      final String jsonData = await loadAsset('assets/haus_b/haus_b_f1.json');

      final loadedGraph = Graph.parseGraph(jsonData);

      // Name-zu-ID-Cache aufbauen
      _nameToIdCache.clear();
      for (var entry in loadedGraph.nodeMap.entries) {
        _nameToIdCache[entry.value.name] = entry.key;
      }

      setState(() {
        graph = loadedGraph;
        jsonCombined = 'Graph mit ${graph.nodeMap.length} Knoten erstellt.';
      });
    } catch (e) {
      log('Fehler beim Laden der Graphdaten: $e');
      setState(() {
        jsonCombined = 'Fehler beim Laden der Graphdaten: $e';
      });
    }
  }

  // Hilfsmethode zur Konvertierung von Namen zu ID
  String? _getNodeIdByName(String name) {
    if (_nameToIdCache.containsKey(name)) {
      return _nameToIdCache[name];
    }

    if (graph.nodeMap.containsKey(name)) {
      return name;
    }

    for (var entry in graph.nodeMap.entries) {
      if (entry.value.name == name) {
        _nameToIdCache[name] = entry.key; // Im Cache speichern
        return entry.key;
      }
    }

    return null;
  }

  // Navigation helpers
  String _getStartNodeId() {
    return _getNodeIdByName(_startValue.trim()) ?? '';
  }

  String _getTargetNodeId() {
    return _getNodeIdByName(_zielValue.trim()) ?? '';
  }

  // Wegfindungs-Methoden
  Future<void> _findPath() async {
    try {
      final stopwatch = Stopwatch()..start();

      final String startId = _getStartNodeId();
      final String targetId = _getTargetNodeId();
      await _findeWeg(startId, targetId);

      final double totalTime = stopwatch.elapsedMicroseconds / 1000;
      log('Button-zu-Ergebnis Zeit: $totalTime ms');
    } catch (e) {
      setState(() => resultText = e.toString());
    }
  }

  Future<void> _findNearestBathroom() async {
    try {
      final String startId = _getStartNodeId();
      final String nearestBathroomId = graph.findNearestBathroomId(startId);

      await _findeWeg(startId, nearestBathroomId);
    } catch (e) {
      setState(() => resultText = e.toString());
    }
  }

  Future<void> _findNearestEmergencyExit() async {
    try {
      final String startId = _getStartNodeId();
      final String nearestExit = graph.findNearestEmergencyExitId(startId);

      await _findeWeg(startId, nearestExit);
    } catch (e) {
      setState(() => resultText = e.toString());
    }
  }

  Future<void> _findeWeg(String startId, String targetId) async {
    try {
      if (startId.isEmpty) {
        setState(() => resultText = 'Bitte wähle einen Startpunkt aus.');
        return;
      }

      if (targetId.isEmpty) {
        setState(() => resultText = 'Bitte wähle ein Ziel aus.');
        return;
      }

      log('Starte Wegfindung von $startId nach $targetId');

      final List<String> instructions = await graph.getNavigationInstructions(
        startId,
        targetId,
      );

      if (instructions.isEmpty) {
        setState(() => resultText = 'Kein Weg gefunden.');
        return;
      }

      setState(() {
        resultText = instructions.join('\n');
      });
    } catch (e) {
      log('Fehler: $e');
      setState(() => resultText = 'Fehler bei der Wegfindung: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> nodeNames =
        graph.nodeMap.values.map((n) => n.name).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Navigator'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: Container(
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
                onStartChanged: (value) => setState(() => _startValue = value),
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

              // Schnellzugriff-Panel
              QuickAccessPanel(
                onBathroomPressed: _findNearestBathroom,
                onExitPressed: _findNearestEmergencyExit,
              ),

              const SizedBox(height: 16),

              // Wegbeschreibung
              Expanded(child: RouteDescriptionPanel(resultText: resultText)),

              // Entwickleroptionen in einem expandierbaren Panel
              DeveloperPanel(graph: graph),
            ],
          ),
        ),
      ),
    );
  }
}
