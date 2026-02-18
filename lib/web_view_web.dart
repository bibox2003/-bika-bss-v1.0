// lib/web_view_web.dart
// WEB ONLY - do not import this file on Android/iOS

import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

class DjangoWebIframe extends StatefulWidget {
  final String url;
  const DjangoWebIframe({super.key, required this.url});

  @override
  State<DjangoWebIframe> createState() => _DjangoWebIframeState();
}

class _DjangoWebIframeState extends State<DjangoWebIframe> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();

    _viewType = 'django-iframe-${DateTime.now().millisecondsSinceEpoch}';

    // Register an iframe view for Flutter Web
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
