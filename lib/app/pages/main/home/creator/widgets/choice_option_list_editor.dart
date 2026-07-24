import 'package:flutter/material.dart';

class ChoiceOptionListEditor extends StatelessWidget {
  const ChoiceOptionListEditor({
    super.key,
    required this.controllers,
    required this.maxOptionLength,
    required this.optionLabelBuilder,
    required this.optionRequiredMessage,
    required this.onReorder,
    required this.onRemove,
    this.minimumOptions = 2,
  });

  final List<TextEditingController> controllers;
  final int maxOptionLength;
  final String Function(int index) optionLabelBuilder;
  final String optionRequiredMessage;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onRemove;
  final int minimumOptions;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controllers.length,
      onReorderItem: onReorder,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final controller = controllers[index];
        return Padding(
          key: ValueKey(controller),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  maxLength: maxOptionLength,
                  decoration: InputDecoration(
                    labelText: optionLabelBuilder(index),
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? optionRequiredMessage
                      : null,
                ),
              ),
              if (controllers.length > minimumOptions)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => onRemove(index),
                ),
            ],
          ),
        );
      },
    );
  }
}
