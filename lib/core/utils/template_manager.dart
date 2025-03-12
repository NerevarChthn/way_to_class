import 'package:way_to_class/core/utils/multi_key_map.dart';

class TemplateManager {
  final MultiKeyMap<String, String> _templates = MultiKeyMap();

  void add(String template, Iterable<String> keys) {
    _templates.add(template, keys);
  }
}
