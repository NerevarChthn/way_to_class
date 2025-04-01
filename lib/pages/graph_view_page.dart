import 'dart:convert';
import 'dart:developer';
import 'dart:math' show max;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:way_to_class/constants/node_data.dart';

class GraphViewScreen extends StatefulWidget {
  const GraphViewScreen({super.key});

  @override
  State<GraphViewScreen> createState() => _GraphViewScreenState();
}

class _GraphViewScreenState extends State<GraphViewScreen> {
  final Graph graph = Graph()..isTree = false;
  Map<String, Node> nodes = {};
  bool isLoading = true;
  String selectedFloor = 'f0';
  String selectedBuilding = 'b';
  Map<String, dynamic>? graphData;
  TransformationController transformationController =
      TransformationController();
  bool showLegend = false;

  @override
  void initState() {
    super.initState();
    loadGraphData();
  }

  Future<void> loadGraphData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String jsonData = await rootBundle.loadString(
        'assets/haus_$selectedBuilding/haus_${selectedBuilding}_$selectedFloor.json',
      );

      graphData = jsonDecode(jsonData);

      // Clear existing nodes and edges
      graph.nodes.clear();
      nodes.clear();

      // Create nodes directly from JSON
      graphData!.forEach((nodeId, nodeData) {
        if (nodeData is Map<String, dynamic>) {
          nodes[nodeId] = Node.id(nodeId);
          graph.addNode(nodes[nodeId]!);
        }
      });

      // Add edges
      graphData!.forEach((nodeId, nodeData) {
        if (nodeData is Map<String, dynamic> &&
            nodeData.containsKey('weights') &&
            nodeData['weights'] is Map) {
          final Map<String, dynamic> weights =
              nodeData['weights'] as Map<String, dynamic>;

          for (final connectedNodeId in weights.keys) {
            if (nodes.containsKey(nodeId) &&
                nodes.containsKey(connectedNodeId)) {
              graph.addEdge(
                nodes[nodeId]!,
                nodes[connectedNodeId]!,
                paint:
                    Paint()
                      ..color = Colors.black
                      ..strokeWidth = 1.0,
              );
            }
          }
        }
      });

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      log('Error loading graph data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Main Interactive Graph
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF3F51B5)),
              )
              : InteractiveViewer(
                transformationController: transformationController,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.01,
                maxScale: 10.0,
                constrained: false,
                child: SizedBox(
                  width: 5000,
                  height: 3000,
                  child: CustomPaint(painter: ModernGraphPainter(graphData!)),
                ),
              ),

          // Control panel
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Map Controls',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Building:'),
                            const SizedBox(height: 4),
                            DropdownButton<String>(
                              value: selectedBuilding,
                              underline: Container(
                                height: 2,
                                color: theme.primaryColor,
                              ),
                              items:
                                  ['a', 'b', 'd', 'e'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text('Building $value'),
                                    );
                                  }).toList(),
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    selectedBuilding = value;
                                    loadGraphData();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Floor:'),
                            const SizedBox(height: 4),
                            DropdownButton<String>(
                              value: selectedFloor,
                              underline: Container(
                                height: 2,
                                color: theme.primaryColor,
                              ),
                              items:
                                  ['f0', 'f1', 'f2', 'f3'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        'Floor ${value.substring(1)}',
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    selectedFloor = value;
                                    loadGraphData();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'refresh',
                          tooltip: 'Refresh Map',
                          onPressed: loadGraphData,
                          child: const Icon(Icons.refresh),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton.small(
                          heroTag: 'zoomIn',
                          tooltip: 'Zoom In',
                          onPressed: () {
                            transformationController.value =
                                transformationController.value.scaled(1.2);
                          },
                          child: const Icon(Icons.zoom_in),
                        ),
                        const SizedBox(width: 12),
                        FloatingActionButton.small(
                          heroTag: 'zoomOut',
                          tooltip: 'Zoom Out',
                          onPressed: () {
                            transformationController.value =
                                transformationController.value.scaled(0.8);
                          },
                          child: const Icon(Icons.zoom_out),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Legend Panel
          if (showLegend)
            Positioned(
              left: 16,
              top: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Map Legend',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => showLegend = false),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLegendItem('Room', Colors.blue[200]!),
                      _buildLegendItem('Corridor', Colors.grey[300]!),
                      _buildLegendItem('Staircase', Colors.green[200]!),
                      _buildLegendItem('Elevator', Colors.amber[300]!),
                      _buildLegendItem('Door', Colors.orange[200]!),
                      _buildLegendItem('Toilet', Colors.cyan[200]!),
                      _buildLegendItem('Machine', Colors.brown[200]!),
                      _buildLegendItem('Emergency Exit', Colors.red[600]!),
                      _buildLegendItem('Coffee Station', Colors.brown[300]!),
                      _buildLegendItem('Other', Colors.purple[200]!),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Reset View',
        onPressed: () {
          transformationController.value = Matrix4.identity();
          // Better starting position
          transformationController.value =
              Matrix4.translationValues(-1000, -600, 0) *
              transformationController.value;
        },
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  Widget _buildLegendItem(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black38, width: 1),
            ),
          ),
          const SizedBox(width: 12),
          Text(name),
        ],
      ),
    );
  }
}

class ModernGraphPainter extends CustomPainter {
  final Map<String, dynamic> graphData;
  final double scaleFactor = 40.0;

  ModernGraphPainter(this.graphData);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset offset = Offset(300, 300);

    // Find min/max coordinates
    int? minX, minY, maxX, maxY;

    graphData.forEach((nodeId, nodeData) {
      if (nodeData is Map<String, dynamic> &&
          nodeData.containsKey('x') &&
          nodeData.containsKey('y')) {
        final int x = nodeData['x'] as int;
        final int y = nodeData['y'] as int;

        minX = minX == null ? x : (x < minX! ? x : minX);
        minY = minY == null ? y : (y < minY! ? y : minY);
        maxX = maxX == null ? x : (x > maxX! ? x : maxX);
        maxY = maxY == null ? y : (y > maxY! ? y : maxY);
      }
    });

    if (minX == null || minY == null || maxX == null || maxY == null) return;

    final double canvasHeight = (maxY! - minY!) * scaleFactor + 400;

    // Draw grid for reference
    _drawGrid(canvas, size, minX!, minY!, maxX!, maxY!, offset, canvasHeight);

    // First pass - draw connections
    graphData.forEach((nodeId, nodeData) {
      if (nodeData is Map<String, dynamic> &&
          nodeData.containsKey('x') &&
          nodeData.containsKey('y')) {
        final int x = nodeData['x'] as int;
        final int y = nodeData['y'] as int;

        final Offset nodePosition = Offset(
          (x * scaleFactor + offset.dx),
          canvasHeight - (y * scaleFactor + offset.dy),
        );

        // Draw connections with better styling
        if (nodeData.containsKey('weights') && nodeData['weights'] is Map) {
          final Map<String, dynamic> weights =
              nodeData['weights'] as Map<String, dynamic>;

          for (final connectedNodeId in weights.keys) {
            var connectedNodeData = graphData[connectedNodeId];

            if (connectedNodeData != null &&
                connectedNodeData is Map<String, dynamic> &&
                connectedNodeData.containsKey('x') &&
                connectedNodeData.containsKey('y')) {
              final int targetX = connectedNodeData['x'] as int;
              final int targetY = connectedNodeData['y'] as int;

              final Offset targetPosition = Offset(
                (targetX * scaleFactor + offset.dx),
                canvasHeight - (targetY * scaleFactor + offset.dy),
              );

              // Style connections based on node types
              final int sourceData = nodeData['data'] as int? ?? 0;
              final int targetData = connectedNodeData['data'] as int? ?? 0;
              final int sourceType = sourceData & 0x1F;
              final int targetType = targetData & 0x1F;

              // Define connection style
              final Paint linePaint =
                  Paint()
                    ..strokeWidth = 1.8
                    ..style = PaintingStyle.stroke;

              // Special connection styling
              if (sourceType == 3 && targetType == 3) {
                // Staircase connection
                linePaint.color = Colors.green.withAlpha(153);
                linePaint.strokeWidth = 2.5;
                _drawDashedLine(
                  canvas,
                  nodePosition,
                  targetPosition,
                  linePaint,
                  4,
                  2,
                );
              } else if (sourceType == 4 && targetType == 4) {
                // Elevator connection
                linePaint.color = Colors.amber.withAlpha(153);
                linePaint.strokeWidth = 2.5;
                _drawDashedLine(
                  canvas,
                  nodePosition,
                  targetPosition,
                  linePaint,
                  4,
                  2,
                );
              } else if (sourceType == 2 && targetType == 2) {
                // Corridor to corridor
                linePaint.color = Colors.grey.withAlpha(102);
              } else {
                // Other connections
                linePaint.color = Colors.blueGrey.withAlpha(128);
              }

              // Draw the line
              if ((sourceType == 3 && targetType == 3) ||
                  (sourceType == 4 && targetType == 4)) {
                // Already drawn as dashed
              } else {
                canvas.drawLine(nodePosition, targetPosition, linePaint);
              }
            }
          }
        }
      }
    });

    // Second pass - draw all nodes
    graphData.forEach((nodeId, nodeData) {
      if (nodeData is Map<String, dynamic> &&
          nodeData.containsKey('x') &&
          nodeData.containsKey('y')) {
        final int data = nodeData['data'] as int? ?? 0;
        final int nodeType = data & nodeMask;
        final int x = nodeData['x'] as int;
        final int y = nodeData['y'] as int;

        final Offset position = Offset(
          (x * scaleFactor + offset.dx),
          canvasHeight - (y * scaleFactor + offset.dy),
        );

        // Modern node styling
        Color fillColor;
        Color strokeColor;
        double size;

        switch (nodeType) {
          case 1: // typeRoom
            fillColor = Colors.blue[200]!;
            strokeColor = Colors.blue[600]!;
            size = 40.0;
            break;
          case 2: // typeCorridor
            fillColor = Colors.grey[300]!;
            strokeColor = Colors.grey[500]!;
            size = 30.0;
            break;
          case 3: // typeStaircase
            fillColor = Colors.green[200]!;
            strokeColor = Colors.green[600]!;
            size = 42.0;
            break;
          case 4: // typeElevator
            fillColor = Colors.amber[300]!;
            strokeColor = Colors.amber[600]!;
            size = 42.0;
            break;
          case 5: // typeDoor
            fillColor = Colors.orange[200]!;
            strokeColor = Colors.orange[600]!;
            size = 40.0;
            break;
          case 6: // typeToilet
            fillColor = Colors.cyan[200]!;
            strokeColor = Colors.cyan[600]!;
            size = 38.0;
            break;
          case 7: // typeMachine
            fillColor = Colors.brown[200]!;
            strokeColor = Colors.brown[600]!;
            size = 38.0;
            break;
          case 8: // typeEmergency
            fillColor = Colors.red[400]!;
            strokeColor = Colors.red[700]!;
            size = 42.0;
            break;
          case 9: // typeCoffee
            fillColor = Colors.brown[300]!;
            strokeColor = Colors.brown[600]!;
            size = 38.0;
            break;
          default:
            fillColor = Colors.purple[200]!;
            strokeColor = Colors.purple[600]!;
            size = 38.0;
        }

        // Apply special properties
        if (((data & 0x40) != 0) && ((data & 0x200) != 0)) {
          // Emergency exit
          fillColor = Colors.red[600]!;
          strokeColor = Colors.red[900]!;
          size = 45.0;
        } else if ((data & 0x20) != 0) {
          // Accessible
          fillColor = Color.lerp(fillColor, Colors.white, 0.2)!;
          strokeColor = Colors.blue[700]!;
        }

        // Text style based on node importance
        final bool isImportantNode = nodeType != 2;

        final textStyle = TextStyle(
          color: isImportantNode ? Colors.black87 : Colors.black54,
          fontSize: isImportantNode ? 13 : 11,
          fontWeight: isImportantNode ? FontWeight.bold : FontWeight.normal,
        );

        final textSpan = TextSpan(
          text: nodeData['name'].toString(),
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(
          minWidth: 0,
          maxWidth: 500,
        ); // Allow more width for measurement

        // Calculate rectangle size based on text dimensions
        // Add padding to ensure text fits comfortably
        final double textWidth = textPainter.width;
        final double textHeight = textPainter.height;
        final double rectWidth = max(
          textWidth + 20,
          size * 1.2,
        ); // Minimum width with padding
        final double rectHeight = max(
          textHeight + 16,
          size,
        ); // Minimum height with padding

        // Modern node style
        final Paint fillPaint =
            Paint()
              ..color = fillColor
              ..style = PaintingStyle.fill;

        final Paint strokePaint =
            Paint()
              ..color = strokeColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0;

        // Node shape based on type
        if (nodeType == 3 || nodeType == 4) {
          // Stairs or elevator
          // Use circles for vertical transitions
          canvas.drawCircle(position, size / 2, fillPaint);
          canvas.drawCircle(position, size / 2, strokePaint);

          // Draw icon inside
          if (nodeType == 3) {
            // Stairs icon
            _drawStairsIcon(canvas, position, size / 2 - 4);
          } else {
            // Elevator icon
            _drawElevatorIcon(canvas, position, size / 2 - 4);
          }
        } else {
          // Use rounded rectangles for other nodes
          final RRect roundedRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: position,
              width: rectWidth,
              height: rectHeight,
            ),
            Radius.circular(8.0),
          );

          // Add shadow effect
          final Paint shadowPaint =
              Paint()
                ..color = Colors.black.withAlpha(51)
                ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);

          final RRect shadowRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(position.dx, position.dy + 2),
              width: rectWidth + 4, // slightly larger for shadow
              height: rectHeight,
            ),
            Radius.circular(8.0),
          );

          canvas.drawRRect(shadowRect, shadowPaint);
          canvas.drawRRect(roundedRect, fillPaint);
          canvas.drawRRect(roundedRect, strokePaint);

          // Draw special icons for some node types
          if (nodeType == 6) {
            // Toilet
            _drawToiletIcon(canvas, position, size / 2 - 4);
          } else if (nodeType == 9) {
            // Coffee
            _drawCoffeeIcon(canvas, position, size / 2 - 4);
          } else if (((data & 0x40) != 0) && ((data & 0x200) != 0)) {
            // Emergency exit
            _drawEmergencyIcon(canvas, position, size / 2 - 4);
          }
        }

        // Recenter text with new rectangle dimensions
        final textOffset = Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2,
        );

        textPainter.paint(canvas, textOffset);
      }
    });
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    int minX,
    int minY,
    int maxX,
    int maxY,
    Offset offset,
    double canvasHeight,
  ) {
    final Paint gridPaint =
        Paint()
          ..color = Colors.grey.withAlpha(26)
          ..strokeWidth = 0.5;

    // Draw horizontal grid lines
    for (int y = minY; y <= maxY; y += 5) {
      final double yPos = canvasHeight - (y * scaleFactor + offset.dy);
      canvas.drawLine(Offset(0, yPos), Offset(size.width, yPos), gridPaint);
    }

    // Draw vertical grid lines
    for (int x = minX; x <= maxX; x += 5) {
      final double xPos = x * scaleFactor + offset.dx;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, canvasHeight), gridPaint);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLength,
    double spaceLength,
  ) {
    double startDistance = 0;
    final double totalDistance = (end - start).distance;
    final Offset normalized = (end - start) / totalDistance;

    while (startDistance < totalDistance) {
      final double endDistance = startDistance + dashLength;
      canvas.drawLine(
        start + normalized * startDistance,
        start +
            normalized *
                (endDistance > totalDistance ? totalDistance : endDistance),
        paint,
      );
      startDistance = endDistance + spaceLength;
    }
  }

  void _drawStairsIcon(Canvas canvas, Offset center, double radius) {
    final Paint iconPaint =
        Paint()
          ..color = Colors.green[700]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final Path path = Path();
    path.moveTo(center.dx - radius / 1.3, center.dy + radius / 1.3);
    path.lineTo(center.dx - radius / 1.3, center.dy);
    path.lineTo(center.dx, center.dy);
    path.lineTo(center.dx, center.dy - radius / 1.3);
    path.lineTo(center.dx + radius / 1.3, center.dy - radius / 1.3);

    canvas.drawPath(path, iconPaint);
  }

  void _drawElevatorIcon(Canvas canvas, Offset center, double radius) {
    final Paint iconPaint =
        Paint()
          ..color = Colors.amber[700]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Draw elevator box
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: radius * 1.2,
        height: radius * 1.5,
      ),
      iconPaint,
    );

    // Draw up arrow
    final Path upArrow = Path();
    upArrow.moveTo(center.dx, center.dy - radius / 2);
    upArrow.lineTo(center.dx - radius / 4, center.dy - radius / 4);
    upArrow.lineTo(center.dx + radius / 4, center.dy - radius / 4);
    upArrow.close();

    // Draw down arrow
    final Path downArrow = Path();
    downArrow.moveTo(center.dx, center.dy + radius / 2);
    downArrow.lineTo(center.dx - radius / 4, center.dy + radius / 4);
    downArrow.lineTo(center.dx + radius / 4, center.dy + radius / 4);
    downArrow.close();

    canvas.drawPath(upArrow, iconPaint..style = PaintingStyle.fill);
    canvas.drawPath(downArrow, iconPaint..style = PaintingStyle.fill);
  }

  void _drawToiletIcon(Canvas canvas, Offset center, double radius) {
    final Paint iconPaint =
        Paint()
          ..color = Colors.cyan[700]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Circle for toilet icon
    canvas.drawCircle(
      Offset(center.dx - radius / 2, center.dy),
      radius / 3,
      iconPaint,
    );
  }

  void _drawCoffeeIcon(Canvas canvas, Offset center, double radius) {
    final Paint iconPaint =
        Paint()
          ..color = Colors.brown[700]!
          ..style = PaintingStyle.fill;

    // Simple coffee cup icon
    final Path cup = Path();
    cup.moveTo(center.dx - radius / 2, center.dy - radius / 2);
    cup.lineTo(center.dx - radius / 2, center.dy + radius / 3);
    cup.quadraticBezierTo(
      center.dx - radius / 2,
      center.dy + radius / 2,
      center.dx,
      center.dy + radius / 2,
    );
    cup.quadraticBezierTo(
      center.dx + radius / 2,
      center.dy + radius / 2,
      center.dx + radius / 2,
      center.dy + radius / 3,
    );
    cup.lineTo(center.dx + radius / 2, center.dy - radius / 2);
    cup.close();

    canvas.drawPath(cup, iconPaint);

    // Steam
    final Path steam = Path();
    steam.moveTo(center.dx, center.dy - radius / 2);
    steam.quadraticBezierTo(
      center.dx + radius / 4,
      center.dy - radius / 1.5,
      center.dx,
      center.dy - radius,
    );

    canvas.drawPath(
      steam,
      Paint()
        ..color = Colors.brown[700]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawEmergencyIcon(Canvas canvas, Offset center, double radius) {
    final Paint iconPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    // Exclamation mark
    canvas.drawRect(
      Rect.fromPoints(
        Offset(center.dx - radius / 6, center.dy - radius / 2),
        Offset(center.dx + radius / 6, center.dy + radius / 5),
      ),
      iconPaint,
    );

    canvas.drawCircle(
      Offset(center.dx, center.dy + radius / 3),
      radius / 6,
      iconPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Placeholder Graph class for compatibility
class Graph {
  List<Node> nodes = [];
  bool isTree = false;

  void addNode(Node node) {
    nodes.add(node);
  }

  void addEdge(Node source, Node target, {required Paint paint}) {
    // Placeholder implementation
  }
}

class Node {
  final String id;

  Node.id(this.id);
}
