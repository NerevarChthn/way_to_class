import 'package:flutter/material.dart';

class FloorViewer extends StatefulWidget {
  const FloorViewer({super.key});

  @override
  State<FloorViewer> createState() => _FloorViewerState();
}

class _FloorViewerState extends State<FloorViewer>
    with SingleTickerProviderStateMixin {
  final List<String> floorImages = [
    'assets/images/floor_0.jpg',
    'assets/images/floor_1.jpg',
    'assets/images/floor_2.jpg',
    'assets/images/floor_3.jpg',
  ];

  final List<String> floorNames = [
    'Erdgeschoss',
    '1. Stock',
    '2. Stock',
    '3. Stock',
  ];

  int currentFloorIndex = 0;
  bool isLegendVisible = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final TransformationController transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void goUp() {
    if (currentFloorIndex < floorImages.length - 1) {
      setState(() {
        currentFloorIndex++;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void goDown() {
    if (currentFloorIndex > 0) {
      setState(() {
        currentFloorIndex--;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void toggleLegend() {
    setState(() {
      isLegendVisible = !isLegendVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final surfaceColor = theme.colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gebäudeplan - ${floorNames[currentFloorIndex]}',
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isLegendVisible ? Icons.info_outline : Icons.info,
              color: primaryColor,
            ),
            onPressed: toggleLegend,
            tooltip: 'Legende anzeigen/verstecken',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map View with Animation
          Positioned.fill(
            child: FadeTransition(
              opacity: _animation,
              child: InteractiveViewer(
                transformationController: transformationController,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.1,
                maxScale: 5.0,
                constrained: true,
                child: Center(
                  child: Hero(
                    tag: 'floormap',
                    child: Image.asset(
                      floorImages[currentFloorIndex],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floor Navigation
          Positioned(
            bottom: 20,
            right: 20,
            child: Card(
              elevation: 4,
              color: Colors.white.withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'upButton',
                      backgroundColor:
                          currentFloorIndex < floorImages.length - 1
                              ? primaryColor
                              : theme.disabledColor,
                      onPressed:
                          currentFloorIndex < floorImages.length - 1
                              ? goUp
                              : null,
                      mini: true,
                      child: const Icon(Icons.keyboard_arrow_up, size: 30),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          floorNames[currentFloorIndex],
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: 'downButton',
                      backgroundColor:
                          currentFloorIndex > 0
                              ? secondaryColor
                              : theme.disabledColor,
                      onPressed: currentFloorIndex > 0 ? goDown : null,
                      mini: true,
                      child: const Icon(Icons.keyboard_arrow_down, size: 30),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Legend Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 20,
            bottom: isLegendVisible ? 20 : -300,
            child: Card(
              elevation: 4,
              color: Colors.white.withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 240,
                height: 300,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Legende',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: toggleLegend,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: const [
                          ColorLegendItem(
                            color: Color(
                              0xFFB5E28C,
                            ), // Pastel green for Seminarraum
                            label: 'Seminarraum',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFEE92B1,
                            ), // Already pastel pink for Computerraum
                            label: 'Computerraum',
                          ),
                          ColorLegendItem(
                            color: Color(0xFFBE9C85), // Pastel brown for Labor
                            label: 'Labor',
                          ),
                          ColorLegendItem(
                            color: Color(0xFFC5CAFF), // Pastel blue for Büro
                            label: 'Büro',
                          ),
                          ColorLegendItem(
                            color: Color(0xFF9BBDEE), // Pastel navy for Mensa
                            label: 'Mensa',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFFFBBE6,
                            ), // Pastel pink for WC Damen (already pastelish)
                            label: 'WC Damen',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFA5EDFF,
                            ), // Pastel blue for WC Herren
                            label: 'WC Herren',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFDAFFAB,
                            ), // Pastel lime for Behinderten WC
                            label: 'Behinderten WC',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFE8E8E8,
                            ), // Lighter gray for Außenanlagen
                            label: 'Außenanlagen',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFF97CDBA,
                            ), // Pastel green for Automat
                            label: 'Automat',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFFFCA94,
                            ), // Pastel orange for Aufzug
                            label: 'Aufzug',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFA3A3FF,
                            ), // Pastel blue for Wasserspender
                            label: 'Wasserspender',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFFFB0B0,
                            ), // Pastel red for Bibliothek
                            label: 'Bibliothek',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFF767676,
                            ), // Lighter black for Hausmeister/IT
                            label: 'Hausmeister/IT',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFBDF5F1,
                            ), // Already pastel aqua for Verwaltung
                            label: 'Verwaltung',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFFFCACA,
                            ), // Lighter pastel pink for Beratung
                            label: 'Beratung',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFD595DA,
                            ), // Pastel purple for Öffentlichkeitsarbeiter
                            label: 'Öffentlichkeitsarbeiter',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFCDCDCD,
                            ), // Lighter gray for Kopierer/Teeküche
                            label: 'Kopierer/Teeküche',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFE8C2FF,
                            ), // Pastel lavender for Lager
                            label: 'Lager',
                          ),
                          ColorLegendItem(
                            color: Color(0xFFFFADAD), // Pastel coral for BMZ
                            label: 'BMZ',
                          ),
                          ColorLegendItem(
                            color: Color(0xFFFFE6D6), // Lighter peach for EDV
                            label: 'EDV',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFFF9ED3,
                            ), // Pastel hot pink for Serverraum
                            label: 'Serverraum',
                          ),
                          ColorLegendItem(
                            color: Color(
                              0xFFFFFFC7,
                            ), // Pastel yellow for Forschungszentrum
                            label: 'Forschungszentrum',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ColorLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const ColorLegendItem({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
