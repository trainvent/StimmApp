import 'package:flutter/material.dart';
import 'package:stimmapp/app/widgets/tag_selector.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/participation_filter.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class OverviewFilterSelection {
  const OverviewFilterSelection({
    required this.tags,
    required this.scopes,
    required this.countryUnions,
    this.onlyMyPublications = false,
    this.participation = ParticipationFilter.notParticipated,
  });
  final List<String> tags;
  final Set<FormScopeType> scopes;
  final Set<CountryUnion> countryUnions;
  final bool onlyMyPublications;
  final ParticipationFilter participation;
}

class OverviewFilterDialog extends StatefulWidget {
  const OverviewFilterDialog({
    super.key,
    required this.initialSelection,
    this.structureFilterSectionBuilder,
    this.filterDialogSectionBuilder,
    this.clearExtraFilters,
    this.showParticipationFilter = false,
  });
  final OverviewFilterSelection initialSelection;
  final bool showParticipationFilter;
  final Widget Function(BuildContext, StateSetter)?
  structureFilterSectionBuilder;
  final Widget Function(BuildContext, StateSetter)? filterDialogSectionBuilder;
  final VoidCallback? clearExtraFilters;

  @override
  State<OverviewFilterDialog> createState() => _OverviewFilterDialogState();
}

class _OverviewFilterDialogState extends State<OverviewFilterDialog> {
  static const List<FormScopeType> _scopeFilterOrder = [
    FormScopeType.global,
    FormScopeType.countryUnion,
    FormScopeType.country,
    FormScopeType.stateOrRegion,
    FormScopeType.city,
  ];
  late List<String> _selectedTags;
  late Set<FormScopeType> _selectedScopes;
  late Set<CountryUnion> _selectedCountryUnions;
  late bool _onlyMyPublications;
  late ParticipationFilter _participation;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.of(widget.initialSelection.tags);
    _selectedScopes = Set.of(widget.initialSelection.scopes);
    _selectedCountryUnions = Set.of(widget.initialSelection.countryUnions);
    _onlyMyPublications = widget.initialSelection.onlyMyPublications;
    _participation = widget.initialSelection.participation;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Keep the width stable as filter sections expand; narrow screens
      // still constrain the dialog to the available space.
      constraints: const BoxConstraints.tightFor(width: 560),
      title: Text(context.l10n.filter),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpansionTile(
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(
                context.l10n.scope,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              children: [
                _buildScopeTargetSelector(
                  selectedScopes: _selectedScopes,
                  selectedCountryUnions: _selectedCountryUnions,
                  onToggle: (scope) {
                    setState(() {
                      if (_selectedScopes.contains(scope)) {
                        _selectedScopes.remove(scope);
                      } else {
                        _selectedScopes.add(scope);
                      }
                    });
                  },
                  onCountryUnionToggle: (union) {
                    setState(() {
                      if (_selectedCountryUnions.contains(union)) {
                        _selectedCountryUnions.remove(union);
                      } else {
                        _selectedCountryUnions.add(union);
                      }
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            ExpansionTile(
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(
                context.l10n.tags,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              children: [
                TagSelector(
                  selectedTags: _selectedTags,
                  maxTags: 10, // Allow more tags for filtering
                  onChanged: (newTags) {
                    setState(() {
                      _selectedTags = newTags;
                    });
                  },
                ),
              ],
            ),
            if (widget.structureFilterSectionBuilder != null) ...[
              const Divider(),
              ExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  context.l10n.structure,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                children: [
                  widget.structureFilterSectionBuilder!(context, setState),
                ],
              ),
            ],
            if (widget.filterDialogSectionBuilder != null) ...[
              const Divider(),
              ExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  context.l10n.groupsLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                children: [
                  widget.filterDialogSectionBuilder!(context, setState),
                ],
              ),
            ],
            if (widget.showParticipationFilter) ...[
              const Divider(),
              ExpansionTile(
                key: const ValueKey('other_filters'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 16),
                title: Text(
                  context.l10n.other,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      context.l10n.participationFilter,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(context.l10n.participationNotYet)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          context.l10n.participationOnly,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    key: const ValueKey('participation_filter_slider'),
                    value: _participation.index.toDouble(),
                    min: 0,
                    max: 2,
                    divisions: 2,
                    label: _participationLabel(_participation),
                    semanticFormatterCallback: (value) => _participationLabel(
                      ParticipationFilter.values[value.round()],
                    ),
                    onChanged: (value) => setState(() {
                      _participation =
                          ParticipationFilter.values[value.round()];
                    }),
                  ),
                  Text(
                    _participationLabel(_participation),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Clear filters
            setState(() {
              _selectedTags = [];
              _selectedScopes = {};
              _selectedCountryUnions = {};
              _onlyMyPublications = false;
              _participation = ParticipationFilter.all;
            });
            widget.clearExtraFilters?.call();
          },
          child: Text(context.l10n.remove),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              OverviewFilterSelection(
                tags: _selectedTags,
                scopes: _selectedScopes,
                countryUnions: _selectedCountryUnions,
                onlyMyPublications: _onlyMyPublications,
                participation: _participation,
              ),
            );
          },
          child: Text(context.l10n.confirm),
        ),
      ],
    );
  }

  String _participationLabel(ParticipationFilter filter) => switch (filter) {
    ParticipationFilter.notParticipated => context.l10n.participationNotYet,
    ParticipationFilter.all => context.l10n.participationAll,
    ParticipationFilter.participated => context.l10n.participationOnly,
  };

  String _scopeLabel(FormScopeType scope) {
    switch (scope) {
      case FormScopeType.global:
        return context.l10n.scopeGlobal;
      case FormScopeType.countryUnion:
        return context.l10n.scopeCountryUnion;
      case FormScopeType.continent:
        return context.l10n.scopeContinent;
      case FormScopeType.country:
        return context.l10n.scopeCountry;
      case FormScopeType.stateOrRegion:
        return context.l10n.scopeStateRegion;
      case FormScopeType.city:
        return context.l10n.scopeCity;
    }
  }

  String _countryUnionLabel(CountryUnion union) => switch (union) {
    CountryUnion.eu => context.l10n.scopeEu,
    CountryUnion.un => context.l10n.scopeUn,
  };

  Widget _buildScopeTargetSelector({
    required Set<FormScopeType> selectedScopes,
    required Set<CountryUnion> selectedCountryUnions,
    required ValueChanged<FormScopeType> onToggle,
    required ValueChanged<CountryUnion> onCountryUnionToggle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    const sizes = <FormScopeType, double>{
      FormScopeType.global: 220,
      FormScopeType.countryUnion: 180,
      FormScopeType.country: 140,
      FormScopeType.stateOrRegion: 100,
      FormScopeType.city: 60,
    };

    return Column(
      children: [
        Center(
          child: SizedBox(
            width: sizes[FormScopeType.global],
            height: sizes[FormScopeType.global],
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (final scope in _scopeFilterOrder)
                  _buildScopeRing(
                    scope: scope,
                    size: sizes[scope]!,
                    isSelected: selectedScopes.contains(scope),
                    onTap: () => onToggle(scope),
                    color: _scopeColor(colorScheme, scope),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final scope in _scopeFilterOrder)
              FilterChip(
                selected: selectedScopes.contains(scope),
                onSelected: (_) => onToggle(scope),
                avatar: CircleAvatar(
                  radius: 8,
                  backgroundColor: _scopeColor(colorScheme, scope),
                ),
                label: Text(_scopeLabel(scope)),
              ),
          ],
        ),
        if (selectedScopes.contains(FormScopeType.countryUnion)) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.selectCountryUnion,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              for (final union in CountryUnion.values)
                FilterChip(
                  selected: selectedCountryUnions.contains(union),
                  onSelected: (_) => onCountryUnionToggle(union),
                  label: Text(_countryUnionLabel(union)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildScopeRing({
    required FormScopeType scope,
    required double size,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? color.withValues(alpha: 0.22)
                  : color.withValues(alpha: 0.08),
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.45),
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: size <= 72
                ? Text(
                    _scopeLabel(scope),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700, color: color),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Color _scopeColor(ColorScheme colorScheme, FormScopeType scope) {
    switch (scope) {
      case FormScopeType.global:
        return colorScheme.primary;
      case FormScopeType.countryUnion:
        return Colors.indigo;
      case FormScopeType.continent:
        return colorScheme.secondary;
      case FormScopeType.country:
        return Colors.teal;
      case FormScopeType.stateOrRegion:
        return Colors.orange;
      case FormScopeType.city:
        return Colors.redAccent;
    }
  }
}
