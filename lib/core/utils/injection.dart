import 'package:get_it/get_it.dart';
import 'package:way_to_class/constants/other.dart';
import 'package:way_to_class/core/components/navigation.dart';
import 'package:way_to_class/core/generator/instruction_generator.dart';
import 'package:way_to_class/core/generator/path_generator.dart';
import 'package:way_to_class/core/generator/segment_generator.dart';
import 'package:way_to_class/core/models/campus_graph.dart';
import 'package:way_to_class/core/utils/transition_manager.dart';
import 'package:way_to_class/service/campus_graph_service.dart';
import 'package:way_to_class/service/graph_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Singleton Services
  getIt.registerLazySingleton<GraphService>(() => GraphService());
  getIt.registerLazySingleton<NavigationHelper>(() => NavigationHelper());
  getIt.registerLazySingleton<TransitionTemplateManager>(
    () => TransitionTemplateManager(),
  );

  // CampusGraph Service
  getIt.registerSingleton<CampusGraphService>(CampusGraphService());
  loadCampusGraph(assetPath);

  // Generator
  getIt.registerLazySingleton<SegmentsGenerator>(() => SegmentsGenerator());
  getIt.registerLazySingleton<PathGenerator>(() => PathGenerator());
  getIt.registerLazySingleton<InstructionGenerator>(
    () => InstructionGenerator(),
  );
}

/// Lädt den Campus-Graphen asynchron
Future<void> loadCampusGraph(String assetPath) async {
  final graphService = getIt<CampusGraphService>();
  final graph = await graphService.loadGraph(assetPath);

  // Register/update the CampusGraph instance
  if (getIt.isRegistered<CampusGraph>()) {
    getIt.unregister<CampusGraph>();
  }
  getIt.registerSingleton<CampusGraph>(graph);
}
