import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DjangoMobileWebView extends StatefulWidget {
  final String url;
  const DjangoMobileWebView({super.key, required this.url});

  @override
  State<DjangoMobileWebView> createState() => _DjangoMobileWebViewState();
}

class _DjangoMobileWebViewState extends State<DjangoMobileWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading) const LinearProgressIndicator(),
      ],
    );
  }
}
