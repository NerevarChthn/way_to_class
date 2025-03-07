# Campus Navigator (Way2Class)

Diese Flutter-App bietet eine Navigation innerhalb eines Campus-Gebäudes. Mithilfe eines Graphen, der verschiedene Knoten (Räume, Flure, Treppen, Fahrstühle, etc.) repräsentiert, wird der kürzeste Pfad zwischen Start- und Zielpunkt berechnet. Die berechneten Pfade werden anschließend in natürliche, verständliche Wegbeschreibungen umgewandelt – unterstützt durch die Google Generative AI.

## Projektstruktur

- **main.dart:**  
  Der Einstiegspunkt der App, in dem die MaterialApp initialisiert und der `WegFinderScreen` als Startseite gesetzt wird.

- **WegFinderScreen:**  
  Die Hauptseite, auf der der Nutzer über Autocomplete-Felder den Start- und Zielpunkt eingeben kann. Hier werden die Buttons für die Wegfindung, das Auffinden von Toiletten oder Notausgängen sowie der Zugriff auf den Graph angezeigt.

- **Graph & Node:**  
  - **Graph:**  
    Verwaltet den gesamten Campus-Graphen, implementiert den A\*-Algorithmus zur Pfadfindung, das Caching der Routenstrukturen und das Laden der Graphdaten aus JSON-Dateien.
  - **Node:**  
    Repräsentiert einzelne Knoten im Graphen (z. B. Räume, Flure, Treppen) mit Typinformationen, Koordinaten und Gewichtungen für die Pfadberechnung.

- **NavigationHelper & RouteSegment:**  
  - **NavigationHelper:**  
    Wandelt den berechneten Pfad in eine Liste von strukturierten `RouteSegment`-Objekten um und generiert damit die Wegbeschreibungen.
  - **RouteSegment:**  
    Definiert die einzelnen Segmente (z. B. „geradeaus gehen“, „links abbiegen“, „Treppe hoch“), die dann zu natürlichen Anweisungen zusammengefasst werden.

- **Hilfsfunktionen:**  
  Zusätzliche Methoden zur Berechnung von Distanzen, Richtungen und zur Erkennung von Übergängen (z. B. bei Etagenwechseln).

## Erweiterung
**TODO:**
korrekte daten ins json, system hinter koordinaten und weights erläutern

## Entwicklungstagebuch

### 20. Februar 2025
---
- **Karte als PNG einlesen:**
    Methode implementieren, um PNG in Bytecode umzuwandeln für Gemini Prompt
- **API-Service Gemini:**
    Methode implementieren, um API-Request an Gemini zu schicken mit Bild und Text als Prompt
- **API-Key:**
    API-Key als Umgebungsvariable mit dotenv hinterlegen im .env file 
- **Haus E Teil 1:**
    ![Haus E, Erdgeschoss](docs/e_f0.png)

### 23. Februar 2025
---
#### Grundlegende UI
- Karte als `InteractiveViewer` im Hintergrund, um Zoomen und Dragging zu ermöglichen
- Zwei `FloatingActionButton` unten rechts: einer öffnet Chat mit Gemini, anderer öffnet Professorentabelle
- `DropdownButton` zur Raumauswahl, anfangs nur Zielraum

### 24. Februar 2025
---
- **Gemini Prompt:**
    Prompt-Generierung und Darstellung des API-Response mit Error-Handling:
    ```dart
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
            TextPart('beschreibe mir kurz wie ich zu Raum $room komme'),
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
    ```
- **Darstellung vom Response:**
    Gemini gibt Response im Markdown Format zurück -> Markdown-Widget, um Response sinnvoll zu visualisieren
    ```dart
    FutureBuilder<String>(
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
    )
    ```
### 26. Februar 2025
---
- **Prompt-Erstellung:**
    Experimenteren mit verschiedenen Text-Prompts, um möglichst optimale Wegbeschreibungen von Gemini zu bekommen
- **Error-Handling:**
    Fehlermeldung wenn zu viele Anfragen zu schnell hintereinander getätigt werden (API-Key is limitiert auf etwa 15 pro Minute)
- **Model-Auswahl:**
    Testen, welches Gemini-Model die besten Ergebnisse liefert
### 27. Februar 2025
---
Aufgrund mangelhafter Ergebnisse bei großen Bildern Erleichterung der Arbeit für Gemini, indem Campus zusätzlich als Graph mit Knoten und Verbindungen hinterlegt wird
- Daten als JSON-Datei bereitstellen
- aus JSON Nodes und Edges parsen -> Graph-Objekt erstellen
- Graph zur Überprüfung visualisieren:
![Graph, Haus E, 2. Etage](docs/e_f2_graph.png)
- JSON Struktur grob überlegen und testen
- **Graph-Erstellung:**
    Graph-Klasse, die Nodes und Edges aus JSON bezieht und daraus Graphenstruktur baut mit angebenen Distanzen

### 28. Februar 2025
---
- Implementierung Such-Algorithmus für den kürzesten Pfad zwischen zwei Knoten (Räumen) -> Dijkstra
- viele Versuche, Richtung korrekt zu berechnen bei allen Situation:
    - Verlassen Raum/Einrichtung/Treppe/...
    - Flur Abbiegung
    - Betreten Raum/Einrichtung/Treppe/...
- Zusammenfassen von Flurabschnitten bei der Wegbeschreibung
- ungefähre Angabe der Schritte/Meter der Strecke basierend auf Koordinatenabstand der Nodes bzw. Schätzung

- **Graphbasierte Navigation:**  
  Der Campus wird als Graph abgebildet, in dem jeder Knoten für einen Raum oder einen Bereich (z. B. Flur, Treppe, Fahrstuhl) steht. Die Knoten enthalten Bitmasken zur Bestimmung des Typs, der Eigenschaften, des Gebäudes und der Etage.

- **Erst Dijkstra**

- **A\*-Algorithmus:**  
  Zur Pfadberechnung wird der A\*-Algorithmus eingesetzt, um den kürzesten Weg zwischen zwei Knoten im Graphen zu finden.

- **Generative AI für Wegbeschreibungen:**  
  Mithilfe des `google_generative_ai`-Pakets werden die strukturierten Routeninformationen in fließende, natürlichsprachliche Anweisungen umgewandelt.

- **Caching:**  
  Berechnete Pfade und Routenstrukturen werden lokal (über `SharedPreferences`) zwischengespeichert, um wiederholte Berechnungen zu vermeiden und die Performance zu verbessern.
  Verschlüsselung der gecachten Daten (um zb sensible Infos wie Professornamen zu schützen)

- **Autocomplete für Start- und Zielauswahl:**  
  Über Autocomplete-Felder können Start- und Zielknoten einfach ausgewählt werden.

- **Graph Visualisierung:**  
  Eine separate Seite (`GraphViewScreen`) ermöglicht die Visualisierung des Graphen zur besseren Übersicht (optional).

### 5. März 2025
---
- Einstellungsseite UI 
- E-Gebäude Räume abgelaufen und überprüft
- A-Gebäude Erdgeschoss abgelaufen und dokumentiert:
![Haus A, Erdgeschoss](docs/a_f0.png)
- farbliche Gruppierung der Räume angepasst
- Legende für Farbzuordnung erstellen
- Verschlüsselung der Cache-Daten und des API-Keys mit den packages `flutter_secure_storage` und `encrypt`
- Testroutine zur Verschlüsselung implementiert
- Test aller möglichen Routen implementiert
- langes Debugging wegen Routen-Errors:
![Routenvalidierung](docs/error_routes.png)