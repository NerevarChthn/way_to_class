import 'package:flutter/material.dart';
import 'package:way_to_class/pages/floors.dart';
import 'package:way_to_class/pages/graph_view_page.dart';

/// A widget that toggles between FloorViewer and GraphViewScreen
class MapViewToggle extends StatefulWidget {
  const MapViewToggle({super.key});

  @override
  State<MapViewToggle> createState() => _MapViewToggleState();
}

class _MapViewToggleState extends State<MapViewToggle> {
  bool _showGraphView = false;

  void _toggleView() {
    setState(() {
      _showGraphView = !_showGraphView;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Main content
        _showGraphView ? const GraphViewScreen() : const FloorViewer(),

        // Toggle button
        Positioned(
          top: 80,
          left: 20,
          child: FloatingActionButton(
            heroTag: 'viewToggleButton',
            backgroundColor: theme.colorScheme.secondary,
            onPressed: _toggleView,
            tooltip:
                _showGraphView
                    ? 'Zur Kartenansicht wechseln'
                    : 'Zur Graphenansicht wechseln',
            child: Icon(
              _showGraphView ? Icons.map : Icons.hub,
              color: theme.colorScheme.onSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
