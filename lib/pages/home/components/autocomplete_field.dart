import 'package:flutter/material.dart';

class NodeAutocompleteField extends StatefulWidget {
  final List<String> nodeNames;
  final String hintText;
  final IconData prefixIcon;
  final String initialValue;
  final ValueChanged<String> onSelected;

  const NodeAutocompleteField({
    super.key,
    required this.nodeNames,
    required this.hintText,
    required this.prefixIcon,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<NodeAutocompleteField> createState() => _NodeAutocompleteFieldState();
}

class _NodeAutocompleteFieldState extends State<NodeAutocompleteField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(NodeAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }

        final query = textEditingValue.text.trim().toLowerCase();
        List<String> matches =
            widget.nodeNames
                .where((option) => option.toLowerCase().contains(query))
                .toList();

        // Sortierung
        matches.sort((a, b) {
          bool aStartsWith = a.toLowerCase().startsWith(query);
          bool bStartsWith = b.toLowerCase().startsWith(query);

          if (aStartsWith && !bStartsWith) return -1;
          if (!aStartsWith && bStartsWith) return 1;
          return a.length - b.length;
        });

        return matches.take(10);
      },
      onSelected: (value) {
        _controller.text = value;
        widget.onSelected(value);
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // Update controller reference
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller.text != textController.text) {
            textController.text = _controller.text;
          }
        });

        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(widget.prefixIcon),
            // Rest der Dekoration
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      // Rest des Autocomplete bleibt gleich...
    );
  }
}
