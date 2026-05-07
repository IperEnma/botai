import 'dart:math';

import 'package:flutter/material.dart';

import '../konecta_tokens.dart';

class ConversationalInput extends StatefulWidget {
  const ConversationalInput({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    required this.metaLeft,
    this.metaRight = '↵ confirmar',
    this.keyboardType,
    this.onSubmitted,
    this.showError = false,
    this.errorText,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final String metaLeft;
  final String metaRight;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final bool showError;
  final String? errorText;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  State<ConversationalInput> createState() => _ConversationalInputState();
}

class _ConversationalInputState extends State<ConversationalInput>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void didUpdateWidget(ConversationalInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.showError && widget.showError) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final underlineSide = const BorderSide(color: KTokens.accent, width: 1.5);
    final underlineBorder = UnderlineInputBorder(borderSide: underlineSide);

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = sin(t * 3 * pi) * (1 - t) * 8;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            onSubmitted: widget.onSubmitted,
            onChanged: widget.onChanged,
            cursorColor: KTokens.accent,
            cursorWidth: 2,
            style: KTokens.tInput,
            buildCounter: widget.maxLength != null
                ? (context,
                    {required currentLength,
                    required isFocused,
                    required maxLength}) {
                    return Text(
                      '$currentLength / $maxLength',
                      style: KTokens.tMonoHint,
                    );
                  }
                : null,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: KTokens.tInput.copyWith(color: KTokens.inkPlaceholder),
              border: underlineBorder,
              enabledBorder: underlineBorder,
              focusedBorder: underlineBorder,
              errorBorder: underlineBorder,
              focusedErrorBorder: underlineBorder,
              contentPadding: const EdgeInsets.only(bottom: 8),
              isDense: true,
            ),
          ),
          if (widget.showError && widget.errorText != null) ...[
            const SizedBox(height: 6),
            Text(widget.errorText!, style: KTokens.tError),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.metaLeft, style: KTokens.tMonoHint),
              Text(widget.metaRight, style: KTokens.tMonoHint),
            ],
          ),
        ],
      ),
    );
  }
}
