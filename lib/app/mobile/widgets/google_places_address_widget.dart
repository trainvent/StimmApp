import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/services/tomtom_search_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class GooglePlacesAddressWidget extends StatefulWidget {
  const GooglePlacesAddressWidget({
    super.key,
    required this.controller,
    required this.onStateChanged,
    this.onTownChanged,
    this.onCountryCodeChanged,
    this.countries,
    this.validator,
  });

  final TextEditingController controller;
  final ValueChanged<String?> onStateChanged;
  final ValueChanged<String?>? onTownChanged;
  final ValueChanged<String?>? onCountryCodeChanged;
  final List<String>? countries;
  final String? Function(String?)? validator;

  @override
  State<GooglePlacesAddressWidget> createState() =>
      GooglePlacesAddressWidgetState();
}

class GooglePlacesAddressWidgetState extends State<GooglePlacesAddressWidget> {
  final _service = TomTomSearchService(IConst.tomTomSearchApiKey);
  final _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  List<TomTomAddressSuggestion> _suggestions = const [];
  bool _isLoading = false;
  bool _isApplyingSuggestion = false;
  int _requestId = 0;
  String? _lastResolvedAddress;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_handleFocusChanged);
    widget.controller.removeListener(_handleTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      unawaited(resolveCurrentTextIfNeeded());
      _removeOverlay();
      return;
    }
    _refreshOverlay();
  }

  void _handleTextChanged() {
    if (_isApplyingSuggestion) {
      return;
    }
    widget.onStateChanged(null);
    widget.onTownChanged?.call(null);
    widget.onCountryCodeChanged?.call(null);
    _lastResolvedAddress = null;

    final text = widget.controller.text.trim();
    _debounce?.cancel();
    if (text.length < 2) {
      setState(() {
        _suggestions = const [];
        _isLoading = false;
      });
      _removeOverlay();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final currentRequestId = ++_requestId;
      setState(() => _isLoading = true);
      final suggestions = await _service.searchAddresses(
        text,
        countries: widget.countries,
      );
      if (!mounted || currentRequestId != _requestId) {
        return;
      }
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
      _refreshOverlay();
    });
  }

  void _refreshOverlay() {
    if (!_focusNode.hasFocus || _suggestions.isEmpty) {
      _removeOverlay();
      return;
    }
    _overlayEntry?.remove();
    _overlayEntry = _createOverlay();
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 6),
          child: TextFieldTapRegion(
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(suggestion.address),
                      subtitle: Text(
                        [
                          suggestion.info.town,
                          suggestion.info.state,
                          suggestion.info.countryCode,
                        ].whereType<String>().where((part) => part.isNotEmpty).join(' • '),
                      ),
                      onTap: () => _selectSuggestion(suggestion),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(TomTomAddressSuggestion suggestion) {
    _isApplyingSuggestion = true;
    _applyResolvedSuggestion(suggestion);
    setState(() {
      _suggestions = const [];
      _isLoading = false;
    });
    _removeOverlay();
    _focusNode.unfocus();
    _isApplyingSuggestion = false;
  }

  Future<void> resolveCurrentTextIfNeeded() async {
    final text = widget.controller.text.trim();
    if (!mounted ||
        text.isEmpty ||
        text.length < 2 ||
        text == _lastResolvedAddress ||
        !_service.hasApiKey) {
      return;
    }

    final exactSuggestion = await _findExactSuggestionMatch(text);
    if (!mounted) {
      return;
    }
    if (exactSuggestion != null) {
      _applyResolvedSuggestion(exactSuggestion);
      return;
    }

    final info = await _service.resolveAddress(text, countries: widget.countries);
    if (!mounted) {
      return;
    }
    if (info.town == null &&
        info.state == null &&
        info.countryCode == null &&
        info.freeformAddress == null) {
      return;
    }

    _lastResolvedAddress = text;
    widget.onStateChanged(info.state);
    widget.onTownChanged?.call(info.town);
    widget.onCountryCodeChanged?.call(info.countryCode);
  }

  Future<TomTomAddressSuggestion?> _findExactSuggestionMatch(String text) async {
    final normalizedText = _normalizeAddress(text);
    TomTomAddressSuggestion? exactSuggestion = _suggestions.cast<TomTomAddressSuggestion?>().firstWhere(
      (suggestion) => suggestion != null && _normalizeAddress(suggestion.address) == normalizedText,
      orElse: () => null,
    );

    if (exactSuggestion != null) {
      return exactSuggestion;
    }

    final suggestions = await _service.searchAddresses(
      text,
      countries: widget.countries,
    );
    if (!mounted) {
      return null;
    }

    exactSuggestion = suggestions.cast<TomTomAddressSuggestion?>().firstWhere(
      (suggestion) => suggestion != null && _normalizeAddress(suggestion.address) == normalizedText,
      orElse: () => null,
    );

    if (exactSuggestion != null) {
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    }

    return exactSuggestion;
  }

  void _applyResolvedSuggestion(TomTomAddressSuggestion suggestion) {
    widget.controller.text = suggestion.address;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.address.length),
    );
    _lastResolvedAddress = suggestion.address.trim();
    widget.onStateChanged(suggestion.info.state);
    widget.onTownChanged?.call(suggestion.info.town);
    widget.onCountryCodeChanged?.call(suggestion.info.countryCode);
  }

  String _normalizeAddress(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  @override
  Widget build(BuildContext context) {
    final isTomTomConfigured = _service.hasApiKey;
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFieldTapRegion(
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: context.l10n.enterYourAddress,
            labelText: context.l10n.address,
            border: const OutlineInputBorder(),
            helperText: isTomTomConfigured
                ? context.l10n.searchPoweredByTomTom
                : context.l10n.setTomTomApiKeyToEnableSuggestions,
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search),
          ),
          validator:
              widget.validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.enterSomething;
                }
                return null;
              },
          onFieldSubmitted: (_) => unawaited(resolveCurrentTextIfNeeded()),
          maxLines: 1,
        ),
      ),
    );
  }
}
