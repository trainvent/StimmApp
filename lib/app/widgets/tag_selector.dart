import 'package:flutter/material.dart';
import 'package:stimmapp/core/constants/app_tags_helper.dart';

class TagSelector extends StatefulWidget {
  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.onChanged,
    this.maxTags = 3,
  });

  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;
  final int maxTags;

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  void _toggleTag(String tagKey) {
    final newTags = List<String>.from(widget.selectedTags);
    if (newTags.contains(tagKey)) {
      newTags.remove(tagKey);
    } else {
      if (newTags.length < widget.maxTags) {
        newTags.add(tagKey);
      } else {
        // Optional: Show a snackbar or feedback that max tags reached
        return;
      }
    }
    widget.onChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    final tagsMap = AppTagsHelper.getTags(context);
    
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: tagsMap.entries.map((entry) {
        final tagKey = entry.key;
        final localizedTag = entry.value;
        final isSelected = widget.selectedTags.contains(tagKey);
        
        return FilterChip(
          label: Text(localizedTag),
          selected: isSelected,
          onSelected: (bool selected) {
            _toggleTag(tagKey);
          },
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }
}
