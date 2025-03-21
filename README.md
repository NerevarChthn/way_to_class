# Campus Navigator (Way2Class)

Diese Flutter-App bietet eine Navigation innerhalb eines Campus-Gebäudes. Mithilfe eines Graphen, der verschiedene Knoten (Räume, Flure, Treppen, Fahrstühle, etc.) repräsentiert, wird der kürzeste Pfad zwischen Start- und Zielpunkt berechnet. Die berechneten Pfade werden anschließend in natürliche, verständliche Wegbeschreibungen umgewandelt – unterstützt durch die Google Generative AI.

## Projektstruktur

- **main.dart:**  
  Der Einstiegspunkt der App, in dem die MaterialApp initialisiert und das Provider-basierte Theme-Management eingerichtet wird. Die HomePage wird als Startseite gesetzt.

- **HomePage:**  
  Die Hauptseite der App mit reaktiver Benutzeroberfläche zum Navigieren auf dem Campus. Bietet Eingabefelder für Start- und Zielpunkt, Schnellzugriffsfunktionen und die Wegbeschreibungsanzeige.

- **Service Layer:**
  - **GraphService:**  
    Implementiert als Singleton, stellt eine zentrale Zugriffsschnittstelle für Graph-Funktionalitäten bereit. Verwaltet das Laden, Caching und die Wiederverwendung von Graph-Daten.
  - **SecurityManager:**  
    Bietet Verschlüsselungsfunktionalität für sensible Daten wie Cache-Inhalte und API-Keys.

- **Graph & Node:**  
  - **Graph:**  
    Enthält die Kernlogik der Navigation - implementiert den A*-Algorithmus zur Pfadfindung, verwaltet das Caching der Routenstrukturen (mit Verschlüsselung) und lädt Graphdaten aus JSON-Dateien.
  - **Node:**  
    Repräsentiert einzelne Knoten im Graphen mit Typinformationen (implementiert als Bitmasken), Koordinaten und Gewichtungen für die Pfadberechnung.

- **NavigationHelper & RouteSegment:**  
  - **NavigationHelper:**  
    Wandelt berechnete Pfade in strukturierte RouteSegment-Objekte um und generiert natürlichsprachliche Wegbeschreibungen.
  - **RouteSegment:**  
    Definiert einzelne Abschnitte einer Route (z.B. "geradeaus gehen", "links abbiegen", "Treppe hoch") mit typsicheren Segmenttypen und zugehörigen Metadaten.

- **UI-Komponenten:**
  - **SearchPanel:** Eingabefelder und Suche für Start- und Zielorte
  - **QuickAccessPanel:** Schnellzugriff auf häufig verwendete Funktionen
  - **RouteDescriptionPanel:** Anzeige der generierten Wegbeschreibungen
  - **DeveloperPanel:** Entwicklerwerkzeuge für Debugging und Tests
  - **GraphViewScreen:** Visualisierung des Campus-Graphen

- **Theme Management:**
  - **ThemeManager:** ChangeNotifier-basierte Klasse zur Verwaltung des App-Themes
  - **LightTheme & DarkTheme:** Separate Konfigurationen für helles und dunkles Erscheinungsbild

- **Hilfsfunktionen:**  
  Zusätzliche Methoden zur Berechnung von Distanzen, Richtungen, Erkennung von Übergängen und zur Optimierung der Cache-Verwaltung.

## Erweiterung
**TODO:**
korrekte daten ins json, system hinter koordinaten und weights erläutern

## Qualitätssicherung und Entwicklungskontrolle

Um sicherzustellen, dass unsere Lösung stets auf dem richtigen Weg bleibt und nicht in falsche Richtungen entwickelt wird, haben wir folgende Maßnahmen implementiert:

### Kontinuierliche Validierung

- **Automatisierte Routentests**: 
  - Implementierung von Tests für alle möglichen Routen im Graphen
  - Validierung der Pfadfindung mit bekannten Start- und Zielpunkten
  - Überprüfung der Wegbeschreibungen auf Korrektheit und Verständlichkeit

  ```dart
  void testAllRoutes() {
    final allNodes = graph.nodeMap.keys.toList();
    int totalRoutes = 0;
    int failedRoutes = 0;
    
    for (String start in allNodes) {
      for (String target in allNodes) {
        if (start != target) {
          totalRoutes++;
          try {
            final path = graph.findPath(start, target);
            if (path.isEmpty) failedRoutes++;
          } catch (e) {
            failedRoutes++;
            print('Fehler bei Route $start -> $target: $e');
          }
        }
      }
    }
    
    print('Getestet: $totalRoutes Routen, Fehler: $failedRoutes');
  }

### Manuelle Feldvalidierung
- Regelmäßige Gebäude-Begehungen zur Datenprüfung
- Sofortige Dokumentation und Korrektur von Abweichungen

### Iterative Entwicklung
- Kurze Zyklen mit realem Nutzerfeedback
- Anpassung auf Basis gesammelter Nutzerbedürfnisse

### Modularität und Architektur
- Klare Trennung von Datenmodell, Algorithmus und UI
- Nutzung austauschbarer, unabhängiger Komponenten

### Code-Qualität
- Regelmäßige Code-Reviews und Pair Programming
- Proaktives Refactoring zur Vermeidung technischer Schulden

### Validierung und Fehlerdokumentation
- Visuelle Pfadprüfung zur Validierung berechneter Ergebnisse
- Dokumentation erkannter Fehler und frühzeitige Reparatur

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

### 1. März 2025
---
- langes Debugging wegen Routen-Errors:
![Routenvalidierung](docs/error_routes.png)
- entwicklertools etc

### 5. März 2025
---
- Einstellungsseite UI 
- E-Gebäude Räume abgelaufen und überprüft
- A-Gebäude Erdgeschoss abgelaufen und dokumentiert:
![Haus A, Erdgeschoss](docs/a_f0.png)
- farbliche Gruppierung der Räume angepasst
- Legende für Farbzuordnung erstellen


### 7. März 2025
---
#### Implementierung von Dark Mode und Theme Management

- **Theme-Manager Architektur**:
  - Implementierung eines `ThemeManager` als ChangeNotifier für reaktives State-Management
  - Integration mit dem Provider-Pattern zur appweiten Theme-Nutzung
  - Methoden zum dynamischen Umschalten zwischen Light- und Darkmode

  ```dart
  class ThemeManager with ChangeNotifier {
    ThemeMode _themeMode = ThemeMode.light;

    ThemeMode get themeMode => _themeMode;
    bool get isDarkMode => _themeMode == ThemeMode.dark;

    void toggleTheme() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

- **Modularer Aufbau**:
  - Erstellung separater Dateien `light_theme.dart` und `dark_theme.dart`.
  - Vereinfachte Wartbarkeit und Anpassbarkeit durch klare Trennung.
  - Definition zentraler Farbkonstanten für konsistente und leicht verwaltbare Farbpaletten.

- **Light Theme Design**:
  - Basis: Blaugraue Farbpalette (Material Blue Grey) mit Teal-Akzenten.
  - Optimierte Kontraste zur Sicherstellung optimaler Lesbarkeit.
  - Leicht getönter Hintergrund (`#F5F7F9`) für angenehme visuelle Tiefe.
  - Einsatz von subtilen Schatten und erhöhter Elevation zur Schaffung einer klaren visuellen Hierarchie.

- **Dark Theme Design**:
  - Basis: Tiefe dunkle Farbtöne (`#121212`) ergänzt durch helle Akzentfarben.
  - Angepasste Farbkontraste zur Reduktion der Augenermüdung.
  - Orientierung an Material Design Dark Theme Guidelines für optimale Lesbarkeit.
  - Reduzierte Elevation-Effekte für ein flacheres und modernes Erscheinungsbild.

- **UI-Komponenten für Theme-Wechsel**:
  - Implementierung eines Icon-Buttons in der AppBar zum schnellen Wechsel zwischen Themes.
  - Kontextabhängige Icons (Sonne/Mond) zur klaren visuellen Indikation des aktuellen Modus.
  - Zusätzlicher Theme-Toggle im Schnellzugriffsbereich der Anwendung für eine intuitive Bedienung.

- **Gestaltung der Tabelle der Professoren:**
    - HTML-Seite einlesen
    - Die Daten der Tabelle extrahieren -> schauen, wo genau die Daten sind in html-Code- Ansicht
    - zunächst als Liste ausgeben lassen -> Erst nur Name
    - Umbau zu Tabelle
    - Drop-Down, weil Tabelle zu breit -> nur Anzeige Name und Raum, dann weitere Infos
    - Automatische Anpassung an Breite der Seite
  
- Dependency Injection GraphService mit GetIt

### 8. März 2025
---
#### Neugestaltung der Professorentabelle

- **Moderne Tabellenansicht**:
  - Ersetzung der klassischen Table-Widgets durch ein flexibles ListView-basiertes Layout für verbesserte Performance
  - Implementierung eines professionellen Headers mit unterschiedlichen Spaltenbreiten (65% für Namen, 35% für Raumnummer)
  - Abgerundete Ecken für bessere visuelle Integration in das App-Design

- **Erweiterte Suchfunktionalität**:
  - Implementierung einer Echtzeit-Suchfunktion mit Filterung nach Namen und Raumnummern
  - Optimierte Suchergebnisanzeige mit Ergebniszähler und visueller Leerstatusmeldung
  - Verbessertes Texteingabefeld mit klarem visuellen Feedback (Lösch-Icon erscheint nur bei Texteingabe)

  ```dart
  final filteredPersons = _searchQuery.isEmpty
      ? widget.persons
      : widget.persons.where((person) {
          final fullName = '${person['name']} ${person['vorname']}'.toLowerCase();
          final room = _formatRoom(person['raum']).toLowerCase();
          final query = _searchQuery.toLowerCase();
          return fullName.contains(query) || room.contains(query);
        }).toList();


- **Interaktive Elemente**
  - Ausklappbare Detailansicht (ExpansionTile)
  - Icons für wichtige Informationen (Telefon, E-Mail)
  
- **Visuelle Hierarchie**
  - Alternierende Zeilenfarben für bessere Lesbarkeit
  - Tabellenkopf farblich hervorgehoben (Primärfarbe)
  - Abgerundete Ecken bei letzter Zeile
  
- **Navigation und Bedienbarkeit**
  - Direkter Theme-Toggle in AppBar mit Kontext-Icons (Sonne/Mond)
  - Navigationsbutton mit visueller Hervorhebung (Sekundärfarbe)
  - Formatierung der Namen („Nachname, Vorname“) und Raumnummern
  
- **Responsive & konsistent**
  - Automatische Anpassung an App-Design und Dark-/Light-Modus
  - Verbessertes Touch-Target-Design

### 9. März 2025
---
#### Neuimplementierung der Wegbeschreibungsgenerierung
- **Struktur:**
  - Generatorenklassen für alle 3 Schritte -> PathGenerator, SegmentsGenerator, InstructionGenerator

### 10.03.25
- Ablaufen der Räume, die noch unklar waren
- Farben der neuen Räume zuordnen
- Legende erstellen mit Farben & Räume

### 11.03.25
- Kleinigkeiten an den Räumen abwandeln
- Große Karte anfangen -> Problem: Beschriftung muss gedreht werden
- Anfangen, alles umzudrehen + Anpassungen an Größe + alle Linien nachziehen für Einheitlichkeit

-**Performance-Verbesserung A-Star:**
  - Vollständige Überarbeitung des A*-Algorithmus zur effizienteren Pfadfindung zwischen Campus-Knoten
  - Optimierung der Heuristik durch präzisere Euklidische Distanz-Berechnung
  - Implementierung spezifischer Gewichtungsmultiplikatoren für verschiedene Knotentypen:
  ```dart
  double weightMultiplier = 1.0;
  if (neighbor.isStaircase) {
    weightMultiplier = 2.0; 
  } else if (neighbor.isElevator) {
    weightMultiplier = 3.0; 
  }

  if (neighbor.isStaircase && !neighbor.isAccessible) {
    weightMultiplier = 10.0; 
  }
  ```
-**Verbesserte Logik bei Etagen-/Gebäudewechsel:**
  - Integration einer etagenübergreifenden Pfadberechnung mit intelligenter Übergangserkennung
  - Implementierung der `_findCrossFloorPath`-Methode für optimale Planung bei Etagenwechseln
  - Überarbeitung der Verbindungserkennung zwischen Treppen und Aufzügen basierend auf räumlicher Nähe:
  ```dart
  bool _areConnectedTransitions(Node transition1, Node transition2) {
    if (transition1.type != transition2.type) return false;

    // Gleiches Gebäude
    if (transition1.buildingCode != transition2.buildingCode) return false;

    // Verschiedene Etagen
    if (transition1.floorCode == transition2.floorCode) return false;

    // Gleiche horizontale Position (x,y) mit Toleranz
    final int dx = (transition1.x - transition2.x).abs();
    final int dy = (transition1.y - transition2.y).abs();

    // Wenn die Knoten ungefähr übereinander liegen
    return dx < 5 && dy < 5;
  }
  ```

### 12. März 2025
---
#### Implementierung eines Logging-Mechanismus für den A*-Algorithmus

- **Ziel**:
  - Verbesserung der Nachvollziehbarkeit und Debugging-Fähigkeit des A*-Algorithmus durch detailliertes Logging und Visualisierung der Algorithmus-Schritte.

- **Logging-Mechanismus**:
  - Einführung eines `enableLogging`-Flags in der `PathGenerator`-Klasse zur Aktivierung des detaillierten Loggings.
  - Nutzung des `dart:developer`-Pakets für konsistente und strukturierte Log-Ausgaben.
  - Implementierung einer Methode `findPathWithVisualization`, die den A*-Algorithmus mit aktiviertem Logging ausführt und die Ergebnisse visualisiert.

  ```dart
  bool enableLogging = false;

  List<NodeId> findPathWithVisualization(
    Path path,
    CampusGraph graph, {
    bool visualize = true,
  }) {
    enableLogging = true;
    final result = calculatePath(path, graph);
    enableLogging = false;
    return result;
  }
  ```

- **Algorithmus-Visualisierung**:
  - Erstellung einer Methode `getAlgorithmVisualization`, die den A*-Algorithmus-Schritt für Schritt ausführt und die Ergebnisse in einem `StringBuffer` sammelt.
  - Detaillierte Ausgabe der aktuellen Knoten, Nachbarn, Heuristik-Werte und Pfadkosten in jeder Iteration des Algorithmus.
  - Visualisierung des finalen Pfades mit Knotendetails und Gesamtkosten.

  ```dart
  String getAlgorithmVisualization(Path path, CampusGraph graph) {
    final NodeId startId = path.$1;
    final NodeId endId = path.$2;

    final Node? start = graph.getNodeById(startId);
    final Node? end = graph.getNodeById(endId);

    if (start == null || end == null) {
      return "Fehler: Start- oder Zielknoten nicht gefunden.";
    }

    final buffer = StringBuffer();
    buffer.writeln("=== A* ALGORITHMUS VISUALISIERUNG ===");
    buffer.writeln("Start: $startId (${start.x}, ${start.y})");
    buffer.writeln("Ziel:  $endId (${end.x}, ${end.y})");
    buffer.writeln("Euklidische Distanz: ${_euclideanDistance(start, end)}");
    buffer.writeln("======================================\n");

    _visualizeAStarSearch(startId, endId, graph, buffer);

    return buffer.toString();
  }
  ```

- **Ergebnisse**:
  - Der Logging-Mechanismus ermöglicht eine detaillierte Nachverfolgung der A*-Algorithmus-Schritte und erleichtert das Debugging und die Optimierung des Pfadfindungsprozesses.
  - Die Visualisierung der Algorithmus-Schritte bietet eine klare und verständliche Darstellung der Pfadberechnung und der Entscheidungsprozesse innerhalb des Algorithmus.

### 13. März 2025

#### 1. Überblick

Der heute implementierte Segment Generator verarbeitet einen Pfad (eine Liste von Node-IDs) und einen CampusGraph, um semantisch sinnvolle Wegsegmente zu erstellen. Dabei werden nicht nur die Knoten des Pfads genutzt, sondern auch kritische Punkte (Breakpoints) wie Richtungsänderungen (Turns) und Typwechsel (z. B. von Flur zu Tür) erkannt und in die Segmentierung integriert. Zusätzlich werden angrenzende _hallway_- und _door_-Segmente zusammengeführt, wobei gemeinsame Metadaten erhalten und erweiterte Werte (z. B. `doorCount` und `distance`) aktualisiert werden.

#### 2. Segmentierung mit `convertPath`

##### 2.1 Funktionale Übersicht

- **Ziel:**  
  Aus einem gegebenen Pfad und CampusGraph werden Wegsegmente (Instanzen von `RouteSegment`) generiert.  
- **Segmenttypen:**  
  - **Origin:** Startet im Raum und leitet in den Flur über.
  - **Turn:** Kennzeichnet eine Richtungsänderung im Flur.
  - **TypeChange:** Wird erzeugt bei einem Wechsel des Knotentyps (z. B. Tür, Treppe, Aufzug).
  - **Destination:** Markiert den Endpunkt (z. B. ein Raum) und berechnet zusätzlich die Flurseite (links/rechts).

##### 2.2 Origin-Segment

- Wird erstellt, wenn der Pfad in einem Raum beginnt.  
- Die ersten drei Knoten werden als `origin`-Segment zusammengefasst, um den Übergang vom Raum in den Flur darzustellen.  
- Der Ursprungsknoten wird danach aus dem Pfad entfernt, um Doppelzählungen zu vermeiden.

##### 2.3 Erkennung der Breakpoints

- **Breakpoints** werden über die Methode `_findPathBreakpoints` ermittelt.
- **Turn-Breakpoints:**  
  - Erkennung erfolgt, wenn in einem Flur ein signifikanter Winkel (über 15°) festgestellt wird.
  - Die Methode berechnet den Winkel anhand von drei aufeinanderfolgenden Knoten und fügt in den Metadaten Informationen wie `direction` hinzu.
- **TypeChange-Breakpoints:**  
  - Treten auf, wenn sich der Knotentyp ändert (z. B. von Flur zu Tür, Treppe oder Aufzug).
  - Hier wird auch eine spezielle Behandlung vorgenommen, um bei Türen den Vorgänger- und Folgeknoten in einem eigenen Segment zu berücksichtigen.

##### 2.4 Segment-Erzeugung und -Verarbeitung

- **Turn-Segmente:**  
  - Der Abbiegungsknoten wird als Endpunkt des vorangegangenen und als Startpunkt des folgenden Segments genutzt.
  - Dadurch wird sichergestellt, dass Distanzen korrekt berechnet werden und der Turn-Winkel in das Segment integriert wird.
- **TypeChange-Segmente:**  
  - Erzeugen ein separates Segment, das den Breakpoint-Knoten und, falls vorhanden, den angrenzenden Knoten umfasst.
- **Finales Segment:**  
  - Das letzte Segment wird überprüft, ob es mindestens zwei Knoten enthält.  
  - Erfüllt der Endknoten Kriterien (Raum, Toilette, Ausgang), wird das Segment als `destination` markiert und die Flurseite ermittelt.

#### 3. Merging von Segmenten

##### 3.1 Ziel des Mergings

Die Merging-Logik fasst angrenzende _hallway_- und _door_-Segmente zusammen, um eine konsistentere Routenbeschreibung zu erzeugen.  
- **Wichtig:**  
  - Abbiegungen (erkennbar über einen nicht-null `direction` in den Metadaten) werden als Trennungen beibehalten und verhindern, dass solche Segmente zusammengeführt werden.
  - Nur Segmente der Typen _hallway_ und _door_ werden zusammengeführt, während andere Typen (z. B. turn, origin, destination) unberührt bleiben.

##### 3.2 Gemeinsame Metadaten und Zusammenführung

- **Gemeinsame Metadaten:**  
  - Für alle Segmente in einer Merge-Gruppe wird ein Schnitt der Metadaten ermittelt.  
  - Nur Schlüssel, die in allen Segmenten vorhanden sind und denselben Wert haben, werden übernommen.
- **Erweiterte Werte:**  
  - Der Wert `distance` wird durch Summierung der Distanzen aus den einzelnen Segmenten aktualisiert.
  - Der Zähler `doorCount` wird entsprechend der Anzahl der Türsegmente (sowie vorhandener `doorCount`-Werte) aktualisiert.
- **Knotenzusammenführung:**  
  - Die Knotensequenzen der zusammengeführten Segmente werden zu einer einzigen Liste fusioniert, wobei Übergänge (duplizierte Knoten) vermieden werden.

#### 4. Code-Struktur und Hilfsfunktionen

##### 4.1 Hilfsfunktionen

- **_createSegment:**  
  - Erzeugt ein `RouteSegment` anhand der gegebenen Knoten, des Segmenttyps und fügt spezifische Metadaten basierend auf dem Typ hinzu (z. B. _hallway_, _door_, _turn_).
- **_calculateTurnDirectionWithAngle:**  
  - Berechnet die Richtung (links/rechts) zwischen drei aufeinanderfolgenden Knoten.
- **_calculatePathDistance & _calculateDistance:**  
  - Ermitteln die Gesamtdistanz eines Segments basierend auf der euklidischen Distanz zwischen den Knoten.
- **_determineSegmentType:**  
  - Bestimmt den Segmenttyp basierend auf den Eigenschaften eines Knotens (z. B. Raum, Flur, Tür, Treppe).

##### 4.2 Breakpoint-Erkennung

- Die Methode `_findPathBreakpoints` analysiert den Pfad und erkennt:
  - **Typwechsel:** Wenn sich der Knotentyp von einem Knoten zum nächsten ändert.
  - **Richtungsänderungen:** Durch Vergleich der Vektoren zwischen den Knoten, wobei ein signifikanter Winkel (über 15°) als Abbiegung interpretiert wird.
  - **Spezialbehandlung für Türen:** Falls ein Türknoten von Flurknoten umgeben ist und in einer geraden Linie liegt, wird er nicht als Breakpoint gewertet.

##### 4.3 Merge-Logik

- **_mergeSegments:**  
  - Führt angrenzende _hallway_- und _door_-Segmente zusammen.
  - Teilt die Merge-Gruppe in Untergruppen, wenn innerhalb der Gruppe Abbiegungen (Turn-Marker) vorhanden sind.
  - Ermittelt gemeinsame Metadaten und aktualisiert `distance` und `doorCount`, ohne andere Metadaten zu überschreiben.
  - Behandelt die Knotenzusammenführung so, dass Duplikate an den Übergängen vermieden werden.


### 12. März 2025
- JSON-Dateien angefangen zu schreiben → über Karte Gitter gelegt für Koordinaten
- Ablaufen der restlichen Räume für vollständigen Plan → weitere Räume in Tabelle noch falsch

### 13. März 2025
- Zeichnung 3. Etage D-Gebäude
- Zeichnung 4. Etage A-Gebäude  
→ Alle einzelnen Gebäude fertig gezeichnet

### 15. März 2025
- Fertigstellen aller großen Karten
- JSON-Datei für E-Gebäude 1. OG komplett

### 16. März 2025
- JSON-Datei für E-Gebäude 2. OG

Heute wurde der `InstructionGenerator` implementiert, eine Dart-Klasse zur dynamischen Generierung natürlicher Sprach-Anweisungen für die Navigation innerhalb von Gebäuden. Die Klasse verwendet zufällig ausgewählte Satzbausteine aus vorbereiteten Templates, um abwechslungsreiche und natürlich klingende Wegbeschreibungen zu erzeugen.

**Implementierungsdetails:**
- Ein interner Zufallsgenerator (`Random`) sorgt für Vielfalt bei der Auswahl von Konnektoren und Templates.
- Drei Arten von Konnektoren (Initial, Mitte, Final) strukturieren die Anweisungen.
- Die Methode `generateInstructions` erzeugt für eine Liste von `RouteSegment` Objekten passende Instruktionen durch Aufruf spezifischer Methoden je nach Segmenttyp.
- Unterstützte Segmenttypen sind:
  - **origin**: Startpunkt-Instruktionen enthalten den Namen des Ursprungsraums, Gebäudes und der Etage.
  - **hallway**: Flur-Anweisungen berücksichtigen Entfernung und ggf. Abbiegerichtungen.
  - **door**: Tür-Durchquerungen erhalten einfache Instruktionen zur Fortsetzung des Wegs.
  - **destination**: Zielraum-Anweisungen geben den genauen Standort relativ zum Flur an.
- Alle Templates nutzen Platzhalter (z.B. `{currentName}`, `{distance}`, `{direction}`), welche mit Metadaten der jeweiligen `RouteSegment` Instanzen befüllt werden.


### 17. März 2025
- JSON-Datei für A-Gebäude EG und 1. OG

### 18. März 2025
- Korrektur A-Gebäude 1. OG
- JSON-Datei für A-Gebäude 2. OG

### 19. März 2025
- JSON-Datei für A-Gebäude 3. OG
- Experimentieren mit Darstellung der Karten in App

### 20. März 2025

#### String Extensions
- **`capitalize()`**  
  Wandelt den ersten Buchstaben eines Strings in einen Großbuchstaben um (bei leerem String wird der Originalstring zurückgegeben).
- **`addPeriod()`**  
  Fügt einen Punkt am Ende hinzu, sofern der String nicht bereits mit `.`, `!` oder `?` endet.
- **`normalizeSpaces()`**  
  Ersetzt Mehrfach-Leerzeichen durch ein einzelnes Leerzeichen und trimmt den String.

#### InstructionGenerator – Finale Version

**Überblick:**  
Die Klasse generiert dynamisch natürliche Navigationsanweisungen für verschiedene Routenabschnitte (Origin, Hallway, Door, Destination). Neu eingeführt wurden:
- Platzhalter-Ersetzung (_replacePlaceholders) zur dynamischen Integration zufälliger Werte.
- Erweiterte Origin- und Hallway-Logik mit Landmarken-Handling und Artikelanpassung.

**Kernfunktionen und Änderungen:**

- **Random Generator Methoden:**  
  - `_getRandomInitialConnector()`, `_getRandomMiddleConnector()`, `_getRandomFinalConnector()`,  
    `_getRandomDistanceWeight()` und `_getRandomHallSynonym()` wählen zufällig Werte aus vordefinierten Listen.
  - **Änderung:** Bei `_getRandomMiddleConnector()` wird der zuletzt genutzte Connector vermieden.

- **reset():**  
  Setzt den internen Zustand zurück (insb. den zuletzt verwendeten Middle Connector).

- **_replacePlaceholders(String text):**  
  Ersetzt Platzhalter wie `{middleConnector}`, `{distanceWeight}` und `{hallSynonym}` im Text durch dynamisch generierte Werte.

- **_optimizeInstructionString(String input):**  
  Optimiert die generierte Anweisung durch Anwenden der String Extensions (normalizeSpaces, addPeriod, capitalize).

- **generateInstructions(List<RouteSegment> route):**  
  - Setzt den Zustand zurück und generiert für jedes Segment eine optimierte Instruktion, indem:
    1. _generateSegmentInstruction aufgerufen wird,
    2. die Platzhalter ersetzt und
    3. das Format final optimiert wird.

- **_generateSegmentInstruction(RouteSegment seg):**  
  Wählt je nach Segmenttyp (origin, hallway, door, destination) die entsprechende Generierungsmethode aus.

- **_generateOriginInstruction(RouteSegment seg):**  
  - **Zweck:** Erzeugt die Anweisung für einen Ursprungsabschnitt.  
  - **Ablauf:**  
    - Startet mit dem Verlassen des Ursprungsraums, unter Einbindung eines zufälligen Initial-Konnektors und des Raum-Namens.
    - Falls eine Richtung definiert ist:
      - Bei gerader Richtung (`straightDirection`) wird „geradeaus“ verwendet.
      - Andernfalls wird der konkrete Richtungswert eingefügt.
    - Der Platzhalter `{hallSynonym}` wird zum Schluss durch einen zufälligen Hallensynonym ersetzt.  
  - **Änderung:** Flexiblere Handhabung der Richtungsangaben, abhängig von der Richtung im Metadaten.

- **_generateHallwayInstruction(RouteSegment seg):**  
  - **Zweck:** Erzeugt eine Wegbeschreibung für Flurabschnitte.  
  - **Ablauf:**  
    - Wählt zufällig eines von zwei Templates, die dynamische Platzhalter enthalten:
      - `{middleConnector}`, `{distanceWeight}`, `{distance}` und `{hallSynonym}`.
    - Ersetzt `{distance}` durch den formatierten Distanzwert.
    - **Neu:**  
      - Falls eine Richtung vorliegt, wird ein zusätzlicher Abschnitt mit einem zufälligen Landmarken-Konnektor (z. B. "auf Höhe von", "bei") angehängt.
      - Der Landmarkenname wird anhand seines Inhalts angepasst:  
        - Enthält er „treppe“, wird „der“ vorangestellt;  
        - enthält er „aufzug“, wird „dem“ verwendet;  
        - ansonsten bleibt er unverändert.
  - **Änderung:** Erweiterte Logik für Landmarken und Richtungsanweisungen.

- **_generateDoorInstruction() & _generateDestinationInstruction():**  
  Platzhalter-Implementierungen, die aktuell noch „Unimplemented“ zurückgeben, inklusive verfügbarer Metadaten.

- **[TODO]:**  
  Erweiterung um GPT Deep Reasoning für Segmentcode mit Beispielen und weiteren Template-Ideen.