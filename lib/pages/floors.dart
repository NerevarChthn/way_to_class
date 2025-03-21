import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FloorViewer extends StatefulWidget {
  const FloorViewer({super.key});

  @override
  _FloorViewerState createState() => _FloorViewerState();
}

class _FloorViewerState extends State<FloorViewer> {
  final List<String> floorImages = [
    'assets/floor1.png',
    'assets/floor2.png',
    'assets/floor3.png',
    'assets/floor4.png',
  ];

  int currentFloorIndex = 0;

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
      appBar: AppBar(title: const Text('Etagenansicht')),
      body: Column(
        children: [
          Expanded(
            child: PhotoView(
              imageProvider: AssetImage(floorImages[currentFloorIndex]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_downward),
                onPressed: currentFloorIndex > 0 ? goDown : null,
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: Icon(Icons.arrow_upward),
                onPressed: currentFloorIndex < floorImages.length - 1 ? goUp : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
