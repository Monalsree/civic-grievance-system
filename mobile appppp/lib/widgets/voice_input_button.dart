import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    required this.controller,
    this.idleColor = const Color(0xFF4B5563),
    this.listeningColor = const Color(0xFFDC2626),
    this.appendText = false,
    this.localeId,
    this.onTextUpdated,
    this.startTooltip = 'Start voice input',
    this.stopTooltip = 'Stop voice input',
    super.key,
  });

  final TextEditingController controller;
  final Color idleColor;
  final Color listeningColor;
  final bool appendText;
  final String? localeId;
  final VoidCallback? onTextUpdated;
  final String startTooltip;
  final String stopTooltip;

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  late final stt.SpeechToText _speech;

  bool _isListening = false;
  String _baseText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
        });

        _showError(error.errorMsg.isEmpty
            ? 'Voice input failed. Please try again.'
            : error.errorMsg);
      },
    );

    if (!available) {
      _showError('Voice input is unavailable on this device.');
      return;
    }

    _baseText = widget.controller.text.trim();

    if (!mounted) return;
    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      localeId: widget.localeId,
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;

        final nextText = widget.appendText && _baseText.isNotEmpty
            ? '$_baseText $words'
            : words;

        widget.controller.value = widget.controller.value.copyWith(
          text: nextText,
          selection: TextSelection.collapsed(offset: nextText.length),
          composing: TextRange.empty,
        );
        widget.onTextUpdated?.call();

        if (result.finalResult && mounted) {
          setState(() {
            _isListening = false;
          });
        }
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _isListening ? widget.stopTooltip : widget.startTooltip,
      onPressed: _toggleListening,
      icon: Icon(
        _isListening ? Icons.mic : Icons.mic_none,
        color: _isListening ? widget.listeningColor : widget.idleColor,
      ),
    );
  }
}
