import 'package:flutter/material.dart';

/// A private reply composer. Keep the draft until the local outbox accepts it.
class StoryReplySheet extends StatefulWidget {
  const StoryReplySheet({
    required this.ownerName,
    required this.isArabic,
    required this.onSend,
    super.key,
  });
  final String ownerName;
  final bool isArabic;
  final Future<void> Function(String text) onSend;
  @override
  State<StoryReplySheet> createState() => _StoryReplySheetState();
}

class _StoryReplySheetState extends State<StoryReplySheet> {
  final _input = TextEditingController();
  bool _sending = false;
  String? _error;

  Future<void> _send() async {
    final text = _input.text.trim();
    if (_sending || text.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.onSend(text);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString().replaceFirst('Bad state: ', '');
        });
    } finally {
      if (mounted)
        setState(() {
          _sending = false;
        });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isArabic
                  ? 'رد خاص على ستوري ${widget.ownerName}'
                  : 'Private reply to ${widget.ownerName}',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _input,
              autofocus: true,
              enabled: !_sending,
              maxLength: 2000,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: widget.isArabic ? 'اكتب رسالة…' : 'Write a message…',
                errorText: _error,
              ),
            ),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(widget.isArabic ? 'إرسال' : 'Send'),
            ),
          ],
        ),
      ),
    ),
  );
}
