import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:way_to_class/screens/prof_screen.dart';
import 'package:way_to_class/service/map_service.dart'; // Gemini API

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isChatOpen = false;
  bool _isTableOpen = false;
  String? _selectedRoom;
  Future<String>? _geminiResponse;
  final List<String> _rooms = ["E318", "E222", "C202", "D303"];

  Future<String> _askGemini(String room) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: dotenv.env['API_KEY'] ?? 'API Key not found',
      );

      final Uint8List imageBytes = await MapService.loadAssetImage(
        'assets/e_gebaeude.png',
      );

      final prompt = Content.multi([
        TextPart(
          'beschreibe mir kurz wie ich zu Raum $room komme und beginne jede antwort mit einem sächsischen spruch',
        ),
        DataPart('image/png', imageBytes),
      ]);

      final response = await model.generateContent([prompt]);
      return response.text ?? "Keine Antwort erhalten.";
    } on ServerException catch (e) {
      return 'ServerException: ${e.message}';
    } catch (e) {
      return 'Fehler bei der Anfrage: $e';
    }
  }

  void _toggleChat() {
    setState(() {
      _isTableOpen = false;
      _isChatOpen = !_isChatOpen;
      _geminiResponse = null;
    });
  }

  void _toggleTable() {
    setState(() {
      _isChatOpen = false;
      _isTableOpen = !_isTableOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Interaktive Karte',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      body: Stack(
        children: [
          // Hintergrund: Die Karte
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 1,
              maxScale: 5.0,
              child: Image.asset("assets/e_gebaeude.png"),
            ),
          ),

          // Dunkler Hintergrund für die modalen Inhalte
          if (_isChatOpen || _isTableOpen)
            Container(color: Colors.black.withValues(alpha: 0.5)),

          // Tabelle Overlay
          if (_isTableOpen)
            Positioned.fill(
              top: MediaQuery.of(context).size.height * 0.2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(blurRadius: 5, color: Colors.black26),
                    ],
                  ),
                  child: HtmlTableScreen(),
                ),
              ),
            ),

          // Chat Overlay
          if (_isChatOpen)
            Positioned.fill(
              top: MediaQuery.of(context).size.height * 0.2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(blurRadius: 5, color: Colors.black26),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton<String>(
                        value: _selectedRoom,
                        hint: const Text("Raum auswählen"),
                        isExpanded: true,
                        items:
                            _rooms.map((room) {
                              return DropdownMenuItem(
                                value: room,
                                child: Text("Raum $room"),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRoom = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed:
                            _selectedRoom == null
                                ? null
                                : () {
                                  setState(() {
                                    _geminiResponse = _askGemini(
                                      _selectedRoom!,
                                    );
                                  });
                                },
                        child: const Text('Wegbeschreibung anfragen'),
                      ),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _geminiResponse,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Text(
                                'Fehler: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Text(
                                "Keine Antwort erhalten.",
                                style: TextStyle(color: Colors.grey),
                              );
                            } else {
                              return Markdown(
                                data: snapshot.data ?? 'Fehler beim Laden',
                              );
                            }
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _toggleChat, // Schließt das Overlay
                        child: const Text("Schließen"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: _toggleTable,
                backgroundColor: Colors.deepPurple,
                child: Icon(
                  _isTableOpen ? Icons.close : Icons.people_alt_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              FloatingActionButton(
                onPressed: _toggleChat,
                backgroundColor: Colors.deepPurple,
                child: Icon(
                  _isChatOpen ? Icons.close : Icons.chat_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
