import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'google_maps_urls.dart';

/// Google Maps embebido vía WebView (sin API key) — Android, iOS y desktop.
class AgendaGoogleMapEmbed extends StatefulWidget {
  const AgendaGoogleMapEmbed({
    super.key,
    required this.embedUrl,
    required this.width,
    required this.height,
    required this.placeholder,
  });

  final String embedUrl;
  final double width;
  final double height;
  final Widget placeholder;

  @override
  State<AgendaGoogleMapEmbed> createState() => _AgendaGoogleMapEmbedIoState();
}

class _AgendaGoogleMapEmbedIoState extends State<AgendaGoogleMapEmbed> {
  WebViewController? _controller;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(AgendaGoogleMapEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedUrl != widget.embedUrl) {
      _failed = false;
      _initController();
    }
  }

  void _initController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (_) {
            if (mounted) setState(() => _failed = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.embedUrl));
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _controller == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.placeholder,
      );
    }
    final crop = GoogleMapsUrls.embedTopChromeCrop;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRect(
        child: IgnorePointer(
          child: Transform.translate(
            offset: Offset(0, -crop),
            child: SizedBox(
              width: widget.width,
              height: widget.height + crop,
              child: WebViewWidget(controller: _controller!),
            ),
          ),
        ),
      ),
    );
  }
}
