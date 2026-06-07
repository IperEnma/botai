import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Google Maps embebido vía iframe (sin API key) — solo web.
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
  State<AgendaGoogleMapEmbed> createState() => _AgendaGoogleMapEmbedState();
}

class _AgendaGoogleMapEmbedState extends State<AgendaGoogleMapEmbed> {
  String? _viewType;

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  @override
  void didUpdateWidget(AgendaGoogleMapEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedUrl != widget.embedUrl ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
      _registerView();
    }
  }

  void _registerView() {
    final viewType =
        'agenda-google-map-${Object.hash(widget.embedUrl, widget.width, widget.height)}';
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = widget.embedUrl
        ..style.border = 'none'
        ..width = '${widget.width}'
        ..height = '${widget.height}'
        ..allowFullscreen = true;
      return iframe;
    });
    _viewType = viewType;
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewType;
    if (viewType == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.placeholder,
      );
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: viewType),
    );
  }
}
