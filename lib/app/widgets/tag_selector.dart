import 'package:flutter/material.dart';
import 'package:stimmapp/app/widgets/tag_wrap.dart';
import 'package:stimmapp/core/constants/app_tags_helper.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class TagSelector extends StatefulWidget {
  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.onChanged,
    this.maxTags = AppLimits.maxTagAmount,
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
        return;
      }
    }
    widget.onChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    final tagsMap = AppTagsHelper.getTags(context);

    final atLimit = widget.selectedTags.length >= widget.maxTags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            context.l10n.tagSelectionCount(
              widget.selectedTags.length,
              widget.maxTags,
            ),
          ),
        ),
        if (atLimit) Text(context.l10n.tagSelectionLimit),
        const SizedBox(height: 8),
        TagWrap(
          children: tagsMap.entries.map((entry) {
            final tagKey = entry.key;
            final localizedTag = entry.value;
            final isSelected = widget.selectedTags.contains(tagKey);

            return FilterChip(
              label: Text(localizedTag),
              selected: isSelected,
              onSelected: !isSelected && atLimit
                  ? null
                  : (_) => _toggleTag(tagKey),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }
}
