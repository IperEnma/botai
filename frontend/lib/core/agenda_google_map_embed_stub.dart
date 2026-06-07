import 'package:flutter/material.dart';

/// En plataformas distintas de web no hay embed gratuito de Google Maps.
class AgendaGoogleMapEmbed extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height, child: placeholder);
  }
}
