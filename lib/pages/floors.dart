import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FloorViewer extends StatefulWidget {
  const FloorViewer({super.key});

  @override
  State<FloorViewer> createState() => _FloorViewerState();
}

class _FloorViewerState extends State<FloorViewer> {
  final List<String> floorImages = [
    'assets/floor_0.png',
    'assets/floor_1.png',
    'assets/floor_2.png',
    'assets/floor_3.png',
  ];

  int currentFloorIndex = 0;

  final TransformationController transformationController = TransformationController();

  void goUp() {
    if (currentFloorIndex < floorImages.length - 1) {
      setState(() {
        currentFloorIndex++;
      });
    }
  }

  void goDown() {
    if (currentFloorIndex > 0) {
      setState(() {
        currentFloorIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: transformationController,
              boundaryMargin: const EdgeInsets.all(0),
              minScale: 0.1,
              maxScale: 5.0,
              constrained: false,
              child: Center(
                child: Image.asset(
                  floorImages[currentFloorIndex],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.blue, // Hintergrundfarbe des Buttons
                  onPressed: currentFloorIndex < floorImages.length - 1 ? goUp : null,
                  child: const Icon(Icons.arrow_drop_up, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  backgroundColor: Colors.red, // Hintergrundfarbe des Buttons
                  onPressed: currentFloorIndex > 0 ? goDown : null,
                  child: const Icon(Icons.arrow_drop_down, size: 40, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}

