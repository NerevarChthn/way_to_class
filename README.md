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
| Thema                     | Beschreibung | Verantwortlich |
|---------------------------|-------------|---------------|
| **Karte als PNG einlesen** | Methode implementieren, um PNG in Bytecode umzuwandeln für Gemini Prompt | Jeremy |
| **API-Service Gemini** | Methode implementieren, um API-Request an Gemini zu schicken mit Bild und Text als Prompt | Jeremy |
| **API-Key** | API-Key als Umgebungsvariable mit dotenv hinterlegen im .env file | Jeremy |
| **Haus E Teil 1** | ![Haus E, Erdgeschoss](docs/e_f0.png) | Pia |

### 23. Februar 2025
---
| Thema                     | Beschreibung | Verantwortlich |
|---------------------------|-------------|---------------|
| **Karte als `InteractiveViewer`** | Ermöglicht Zoomen und Dragging | Jeremy |
| **Zwei `FloatingActionButton`** | Einer öffnet Chat mit Gemini, anderer öffnet Professorentabelle | Jeremy |
| **`DropdownButton` zur Raumauswahl** | Anfangs nur Zielraum | Jeremy |

## Entwicklungstagebuch

### 24. Februar 2025
---
| Thema                     | Beschreibung | Verantwortlich |
|---------------------------|-------------|---------------|
| **Gemini Prompt** | Prompt-Generierung und Darstellung des API-Response mit Error-Handling | Jeremy |
| **Darstellung vom Response** | Markdown-Widget zur Visualisierung des Gemini-Responses | Jeremy |

### 26. Februar 2025
---
| Thema                     | Beschreibung | Verantwortlich |
|---------------------------|-------------|---------------|
| **Prompt-Erstellung** | Optimierung von Text-Prompts für bessere Wegbeschreibungen | Jeremy |
| **Error-Handling** | Fehlermeldungen bei zu vielen Anfragen | Jeremy |
| **Model-Auswahl** | Testen, welches Gemini-Model die besten Ergebnisse liefert | Jeremy |

### 27. Februar 2025
---
| Thema                     | Beschreibung | Verantwortlich |
|---------------------------|-------------|---------------|
| **Graph-Erstellung** | Campus-Graph mit JSON-Nodes und Edges, inklusive Visualisierung | Jeremy |
| **Graph-Visualisierung** | Visualisierung zur Überprüfung der Graphstruktur | Jeremy |

### 28. Februar 2025
---
| Thema                     | Beschreibung | Verantwortlich |
|---------------------------|-------------|---------------|
| **Such-Algorithmus** | Implementierung von Dijkstra und A\*-Algorithmus zur Pfadberechnung | Jeremy |
| **Routenoptimierung** | Korrekte Berechnung der Richtung und sinnvolle Zusammenfassung von Flurabschnitten | Jeremy |
| **Schrittschätzung** | Angabe der ungefähren Distanz in Metern/Schritten | Jeremy |
| **Graphbasierte Navigation** | Abbildung des Campus als Graph mit Bitmasken zur Typ- und Gebäudeerkennung | Jeremy |
| **Generative AI für Wegbeschreibungen** | Nutzung des `google_generative_ai`-Pakets zur Sprachgenerierung | Jeremy |
| **Caching** | Speicherung berechneter Routen zur Performance-Optimierung | Jeremy |
| **Autocomplete** | Felder zur einfachen Auswahl von Start- und Zielknoten | Jeremy |
| **Graph-Visualisierung** | Separate Seite zur Visualisierung des Graphen (`GraphViewScreen`) | Jeremy |

### 1. März 2025
---
| Thema                     | Beschreibung | Verantwortlich |
|---------------------------|-------------|---------------|
| **Debugging** | Längere Debugging-Session zur Fehlerbehebung bei Routen | Jeremy |
| **Entwicklertools** | Verbesserung der Debugging- und Entwicklungswerkzeuge | Jeremy |

### 5. März 2025
---
| Thema                     | Beschreibung | Verantwortlich |
|---------------------------|-------------|---------------|
| **Einstellungsseite UI** | Gestaltung und Implementierung der Einstellungsseite | Pia |
| **E-Gebäude Überprüfung** | Räume im E-Gebäude abgelaufen und überprüft | Pia |
| **A-Gebäude Dokumentation** | Erdgeschoss des A-Gebäudes abgelaufen und dokumentiert | Pia |
| **Farbliche Gruppierung** | Anpassung der Farbgruppen für Räume | Pia |
| **Legende für Farbzuordnung** | Erstellung einer Legende zur Farbzuordnung | Pia |


### 7. März 2025
---
| Thema                     | Beschreibung | Verantwortlich |
|---------------------------|-------------|---------------|
| **Theme-Manager Architektur** | Implementierung eines `ThemeManager` als ChangeNotifier mit Provider-Pattern für reaktives Theme-Management | Jeremy |
| **Modularer Aufbau** | Trennung in `light_theme.dart` und `dark_theme.dart` für bessere Wartbarkeit | Jeremy |
| **Light Theme Design** | Blaugraue Farbpalette mit Teal-Akzenten und optimierten Kontrasten | Jeremy |
| **Dark Theme Design** | Dunkle Farbtöne mit hellen Akzenten und reduzierten Elevation-Effekten | Jeremy |
| **UI-Komponenten für Theme-Wechsel** | Icon-Button in der AppBar und zusätzlicher Toggle im Schnellzugriffsbereich | Jeremy |
| **Professoren-Tabelle** | Extraktion von Daten aus HTML-Tabelle, Umwandlung zur Tabelle mit Dropdown-Funktion zur kompakten Darstellung | Pia |
| **Dependency Injection** | Implementierung von `GraphService` mit `GetIt` zur Dependency Injection | Jeremy |

### 8. März 2025
---
| Thema                     | Beschreibung | Verantwortlich |
|---------------------------|-------------|---------------|
| **Moderne Tabellenansicht** | Ersetzung der Table-Widgets durch ListView für bessere Performance, inkl. flexible Spaltenbreiten und abgerundete Ecken | Jeremy |
| **Erweiterte Suchfunktionalität** | Echtzeit-Suche mit Filterung nach Namen/Raumnummer, Ergebniszähler und verbessertes Texteingabefeld | Jeremy |
| **Interaktive Elemente** | Ausklappbare Detailansicht (ExpansionTile) und Icons für wichtige Informationen (Telefon, E-Mail) | Jeremy |
| **Visuelle Hierarchie** | Alternierende Zeilenfarben, farblich hervorgehobener Tabellenkopf und abgerundete Ecken bei der letzten Zeile | Jeremy |
| **Navigation und Bedienbarkeit** | Theme-Toggle in der AppBar, Navigationsbutton und optimierte Namens-/Raumformatierung | Jeremy |
| **Responsive & konsistent** | Automatische Anpassung an Dark-/Light-Modus und optimiertes Touch-Target-Design | Jeremy |

### 9. März 2025
---
| Thema                     | Beschreibung | Verantwortlich |
|---------------------------|-------------|---------------|
| **Neuimplementierung der Wegbeschreibungsgenerierung** | Einführung von `PathGenerator`, `SegmentsGenerator` und `InstructionGenerator` zur strukturierten Erstellung von Wegbeschreibungen | Jeremy |

### 10. März 2025
---
| Thema                                   | Beschreibung                                                        | Verantwortlich |
|-----------------------------------------|--------------------------------------------------------------------|---------------|
| **Raumablauf und Zuordnung**            | Ablaufen der Räume, die noch unklar waren und Zuordnung der Farben | Pia           |
| **Legende Erstellung**                  | Erstellung einer Legende mit Farben und entsprechenden Räumen      | Pia           |

### 11. März 2025
---
| Thema                                   | Beschreibung                                                        | Verantwortlich |
|-----------------------------------------|--------------------------------------------------------------------|---------------|
| **Raumanpassungen und Kartenoptimierung** | Kleinigkeiten an den Räumen abwandeln, Karte anfangen und Anpassungen an Größe, Drehung und Linienvorbereitung für Einheitlichkeit | Jeremy |
| **Performance-Verbesserung A-Star**      | Überarbeitung des A*-Algorithmus für effizientere Pfadfindung, Optimierung der Heuristik und Implementierung von Gewichtungsmultiplikatoren für Knotenarten | Jeremy |
| **Verbesserte Etagen-/Gebäudewechsel-Logik** | Integration einer etagenübergreifenden Pfadberechnung und Überarbeitung der Verbindungserkennung für Treppen und Aufzüge | Jeremy |
| **Implementierung eines Logging-Mechanismus** | Implementierung eines detaillierten Loggings und einer Visualisierung der A*-Algorithmus-Schritte zur besseren Nachvollziehbarkeit und Debugging | Jeremy |
| **Segment Generator Implementierung**   | Implementierung eines Segment Generators zur Erstellung von semantischen Wegsegmenten unter Berücksichtigung von Richtungsänderungen und Typwechseln | Jeremy |
| **Segment Merging**                     | Merging von angrenzenden _hallway_- und _door_-Segmenten zur Vereinheitlichung der Routenbeschreibung | Jeremy |

### 12. März 2025
---
| Thema                                   | Beschreibung                                                        | Verantwortlich |
|-----------------------------------------|--------------------------------------------------------------------|---------------|
| **JSON-Tool** | Bau eines Python-Skriptes zum schnellen Erstellen der JSON-Dateien | Jeremy |
| **JSON-Dateien und Gitter-Koordinaten** | Beginn der Erstellung von JSON-Dateien und Überlagerung eines Gitters auf die Karte zur Festlegung der Koordinaten | Pia |
| **Raumüberprüfung und -anpassung**      | Ablaufen der restlichen Räume zur Erstellung eines vollständigen Plans, Anpassungen der Tabelle mit weiteren falschen Raumdaten | Jeremy |
| **Performance-Verbesserung A-Star**      | Optimierung des A*-Algorithmus durch Implementierung von Gewichtungsmultiplikatoren und einer verbesserten Heuristik für effizientere Pfadfindung | Jeremy |

### 13. März 2025
---
| Thema                                   | Beschreibung                                                         | Verantwortlich |
|-----------------------------------------|---------------------------------------------------------------------|---------------|
| **Zeichnung 3. Etage D-Gebäude**        | Fertigstellung der Zeichnung für die 3. Etage im D-Gebäude          | Pia |
| **Zeichnung 4. Etage A-Gebäude**        | Fertigstellung der Zeichnung für die 4. Etage im A-Gebäude          | Pia |
| **Fertigstellung aller Gebäudezeichnungen** | Alle einzelnen Gebäude vollständig gezeichnet                      | Pia |

### 15. März 2025
---
| Thema                                   | Beschreibung                                                         | Verantwortlich |
|-----------------------------------------|---------------------------------------------------------------------|---------------|
| **Fertigstellen aller großen Karten**  | Abschluss der Erstellung aller großen Campus-Karten                 | Pia |
| **JSON-Datei für E-Gebäude 1. OG**      | Fertigstellung der JSON-Datei für das 1. Obergeschoss im E-Gebäude | Pia |

### 16. März 2025
---
| Thema                                   | Beschreibung                                                         | Verantwortlich |
|-----------------------------------------|---------------------------------------------------------------------|---------------|
| **JSON-Datei für E-Gebäude 2. OG**      | Fertigstellung der JSON-Datei für das 2. Obergeschoss im E-Gebäude  | Pia |
| **Implementierung des `InstructionGenerator`** | Entwicklung einer Dart-Klasse zur Generierung natürlicher Sprach-Anweisungen für die Navigation | Jeremy |
| **Detailbeschreibung des `InstructionGenerator`** | Zufällige Auswahl von Satzbausteinen und Templates für diverse Wegbeschreibungen, basierend auf Segmenttypen wie Origin, Hallway, Door und Destination | Jeremy |

### 17. März 2025
---
| Thema                                    | Beschreibung                                                      | Verantwortlich |
|------------------------------------------|------------------------------------------------------------------|---------------|
| **JSON-Datei für A-Gebäude EG und 1. OG** | Erstellung der JSON-Dateien für das Erdgeschoss und 1. Obergeschoss im A-Gebäude | Pia |

### 18. März 2025
---
| Thema                                    | Beschreibung                                                      | Verantwortlich |
|------------------------------------------|------------------------------------------------------------------|---------------|
| **Korrektur A-Gebäude 1. OG**             | Anpassungen und Korrekturen an der JSON-Datei für das 1. Obergeschoss im A-Gebäude | Pia |
| **JSON-Datei für A-Gebäude 2. OG**        | Fertigstellung der JSON-Datei für das 2. Obergeschoss im A-Gebäude | Pia |

### 19. März 2025
---
| Thema                                    | Beschreibung                                                      | Verantwortlich |
|------------------------------------------|------------------------------------------------------------------|---------------|
| **JSON-Datei für A-Gebäude 3. OG**        | Fertigstellung der JSON-Datei für das 3. Obergeschoss im A-Gebäude | Pia |
| **Experimentieren mit Darstellung der Karten in App** | Tests zur visuellen Darstellung der Karten in der App | Pia |

### 20. März 2025
---
| Thema                                    | Beschreibung                                                      | Verantwortlich |
|------------------------------------------|------------------------------------------------------------------|---------------|
| **String Extensions**                    | Implementierung von Methoden zur String-Modifikation, einschließlich `capitalize()`, `addPeriod()`, `normalizeSpaces()` | Jeremy |
| **InstructionGenerator – Finale Version** | Fertigstellung der finalen Version des `InstructionGenerator` mit erweiterten Methoden zur Generierung von Navigationsanweisungen, Platzhalter-Ersetzung und optimierter Anweisungslogik | Jeremy |

### 25. März 2025
---
| Thema                                    | Beschreibung                                                      | Verantwortlich |
|------------------------------------------|------------------------------------------------------------------|---------------|
| **Raumsuche optimiert**                  | Raumsuche erkennt jetzt auch Räume, wenn man potenzielle Nullen weglässt (z.B. a4 findet auch A004) | Jeremy |

### 26. März 2025
---
| Thema                                    | Beschreibung                                                      | Verantwortlich |
|------------------------------------------|------------------------------------------------------------------|---------------|
| **Verbesserte Treppen- und Aufzugserkennung** | Implementierung spezifischer Erkennungsalgorithmen für Treppen- und Aufzugsverbindungen zwischen Etagen mit Pattern-Matching und direkter ID-Analyse | Jeremy |
| **Priorisierung von Treppen** | Überarbeitung des Routing-Algorithmus zur Bevorzugung von Treppen gegenüber Aufzügen, wenn sich beide im gleichen Gebäude befinden | Jeremy |

### 27. März 2025
---


### 28. März 2025
---
| Thema                                    | Beschreibung                                                      | Verantwortlich |
|------------------------------------------|------------------------------------------------------------------|---------------|
| **Performance-Optimierung der HomePage** | Umstellung des Graph-Ladens von FutureBuilder auf einmaliges Laden beim App-Start zur Vermeidung wiederholter Graph-Neukonstruktion | Jeremy |
| **Zustandsmanagement-Verbesserung**      | Optimierung des setState-Verhaltens, um unnötige Neuberechnungen zu vermeiden | Jeremy |
| **Umstellung auf bidirektionale Suche**  | Der A* Algorithmus wurde verworfen und durch eine bidirektionale Suche ersetzt. Diese Methode führt die Suche sowohl von Start- als auch Zielpunkt gleichzeitig durch, um schneller den gemeinsamen Schnittpunkt zu finden. | Jeremy |

### 29. März 2025
---
| Thema                                    | Beschreibung                                                      | Verantwortlich |
|------------------------------------------|------------------------------------------------------------------|---------------|
| **Erweitertes Logging-System** | Implementation eines detaillierten, mehrstufigen Logging-Systems für besseres Debugging der Pfadfindung und Segmentierung | Jeremy |
| **Deduplizierung von Log-Aufrufen** | Optimierung des Loggings zur Vermeidung doppelter Log-Meldungen bei der Pfadberechnung | Jeremy |

### 30. März 2025
---
| Thema                                    | Beschreibung                                                      | Verantwortlich |
|------------------------------------------|------------------------------------------------------------------|---------------|
| **Erweiterte Breakpoint-Erkennung** | Implementierung spezieller Breakpoint-Typen (Abbiegung, Treppe, Aufzug, Typwechsel) mit hierarchischer Priorisierung | Jeremy |
| **Zusammenhängende Treppensegmente** | Algorithmus zur Erkennung von zusammenhängenden Treppen als einheitliches Segment mit Start-/Endpunkterkennung | Jeremy |
| **MapViewToggle Widget** | Implementierung eines neuen Widget-Systems zum Umschalten zwischen Kartenansicht (FloorViewer) und Graphenansicht (GraphViewScreen) mit einem FloatingActionButton | Jeremy |
| **Verbesserte UI Navigation** | Erweiterung der Benutzeroberfläche um einen kontextabhängigen Toggle-Button, der dynamisch seinen Icon und Tooltip basierend auf dem aktuellen Anzeigemodus ändert | Jeremy |
| **State Management für Ansichtsmodi** | Integration eines zustandsbasierten Ansichtsumschalters, der den aktuellen Anzeigemodus (Karte oder Graph) persistent hält und nahtlos zwischen den Ansichten wechselt | Jeremy |