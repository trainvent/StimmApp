import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

class WebAdSenseFrame extends StatefulWidget {
  const WebAdSenseFrame({super.key, required this.adSlot, this.height = 96});

  final String adSlot;
  final double height;

  @override
  State<WebAdSenseFrame> createState() => _WebAdSenseFrameState();
}

class _WebAdSenseFrameState extends State<WebAdSenseFrame> {
  static int _nextId = 0;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'adsense-frame-${_nextId++}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src =
            'adview.html?slot=${Uri.encodeComponent(widget.adSlot)}'
            '&height=${widget.height.round()}'
            '&format=horizontal'
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '${widget.height}px'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = 'transparent';
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
