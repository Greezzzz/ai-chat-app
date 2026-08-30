import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_theme.dart';

/// Message composer: text field + send button.
///
/// - Empty input → send disabled.
/// - While streaming → button becomes Stop (optional MVP enhancement).
/// - While a context document is uploading → input + send disabled.
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.onSend,
    this.onStop,
    this.isStreaming = false,
    this.isUploadingContext = false,
  });

  final ValueChanged<String> onSend;
  final VoidCallback? onStop;
  final bool isStreaming;

  /// True while a context document is being uploaded; the composer is
  /// disabled so the first message can't be sent before it's ready.
  final bool isUploadingContext;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isStreaming || widget.isUploadingContext) {
      return;
    }
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;
    final disabled = widget.isStreaming || widget.isUploadingContext;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: neo.background,
        border: Border(
          top: BorderSide(color: neo.border, width: neo.borderWidth),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !disabled,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: widget.isStreaming
                      ? 'AI is responding...'
                      : 'Ask anything...',
                  filled: true,
                  fillColor: neo.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: neo.border,
                      width: neo.borderWidth,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: neo.border,
                      width: neo.borderWidth,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: neo.ink,
                      width: neo.borderWidth + 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Send / Stop button.
            Material(
              color: widget.isStreaming
                  ? neo.error
                  : (widget.isUploadingContext ? neo.surface : neo.accent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                side: BorderSide(color: neo.border, width: neo.borderWidth),
              ),
              elevation: 0,
              child: InkWell(
                onTap: widget.isStreaming
                    ? widget.onStop
                    : (widget.isUploadingContext
                        ? null
                        : (_hasText ? _submit : null)),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  child: Icon(
                    widget.isStreaming
                        ? Icons.stop_rounded
                        : Icons.send_rounded,
                    size: 22,
                    color: widget.isUploadingContext && !widget.isStreaming
                        ? neo.inkMuted
                        : neo.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
