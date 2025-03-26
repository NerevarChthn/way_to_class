import 'package:get_it/get_it.dart';
import 'package:way_to_class/core/generator/instruction_generator.dart';
import 'package:way_to_class/core/generator/path_generator.dart';
import 'package:way_to_class/core/generator/segment_generator.dart';
import 'package:way_to_class/service/campus_graph_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Stellen wir sicher, dass die Generatoren zuerst registriert werden
  if (!getIt.isRegistered<PathGenerator>()) {
    getIt.registerSingleton<PathGenerator>(PathGenerator());
  }

  if (!getIt.isRegistered<SegmentsGenerator>()) {
    getIt.registerSingleton<SegmentsGenerator>(SegmentsGenerator());
  }

  if (!getIt.isRegistered<InstructionGenerator>()) {
    getIt.registerSingleton<InstructionGenerator>(InstructionGenerator());
  }

  // CampusGraph Service sollte nach den Generatoren registriert werden
  if (!getIt.isRegistered<CampusGraphService>()) {
    getIt.registerSingleton<CampusGraphService>(CampusGraphService());
  }
}
