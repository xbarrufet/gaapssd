import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../app/theme/app_theme.dart';

class CommentController extends TextEditingController {}

class NotesDictateSection extends StatefulWidget {
  const NotesDictateSection({
    super.key,
    required this.controller,
    required this.onSave,
    this.onDelete,
  });

  final TextEditingController controller;
  final Future<void> Function() onSave;
  final VoidCallback? onDelete;

  @override
  State<NotesDictateSection> createState() => _NotesDictateSectionState();
}

class _NotesDictateSectionState extends State<NotesDictateSection> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  String _dictationBaseText = '';
  Timer? _autosaveTimer;
  bool _saveInFlight = false;
  bool _pendingSave = false;
  late String _lastSavedText;

  static const _autosaveDebounce = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _lastSavedText = widget.controller.text.trim();
  }

  Future<void> _flushSave({required bool force}) async {
    final currentText = widget.controller.text.trim();
    if (!force && currentText == _lastSavedText) {
      return;
    }

    if (_saveInFlight) {
      _pendingSave = true;
      return;
    }

    _saveInFlight = true;
    try {
      await widget.onSave();
      _lastSavedText = currentText;
    } finally {
      _saveInFlight = false;
    }

    if (_pendingSave) {
      _pendingSave = false;
      await _flushSave(force: false);
    }
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDebounce, () {
      if (!mounted) {
        return;
      }
      unawaited(_flushSave(force: false));
    });
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    // Best-effort save — ignore errors since the widget tree is being torn down.
    unawaited(_flushSave(force: false).catchError((_) {}));
    _speech.stop();
    super.dispose();
  }

  Future<void> _startDictation() async {
    final isReady = _speechReady
        ? true
        : await _speech.initialize(
            onStatus: (status) {
              if (!mounted) {
                return;
              }
              if (status == 'done' || status == 'notListening') {
                setState(() => _isListening = false);
              }
            },
            onError: (_) {
              if (!mounted) {
                return;
              }
              setState(() => _isListening = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se pudo iniciar el dictado')),
              );
            },
          );

    if (!isReady) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El dictado no esta disponible en este dispositivo')),
      );
      return;
    }

    _speechReady = true;
    _dictationBaseText = widget.controller.text.trim();

    if (mounted) {
      setState(() => _isListening = true);
    }

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (result) {
        if (!mounted) {
          return;
        }

        final spoken = result.recognizedWords.trim();
        final merged = _dictationBaseText.isEmpty
            ? spoken
            : (spoken.isEmpty ? _dictationBaseText : '$_dictationBaseText $spoken');

        widget.controller
          ..text = merged
          ..selection = TextSelection.collapsed(offset: merged.length);

        _scheduleAutosave();
      },
    );
  }

  Future<void> _stopDictation() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _toggleDictation() async {
    if (_isListening) {
      await _stopDictation();
      return;
    }
    await _startDictation();
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;

    return Column(
      children: [
        isCupertino
            ? CupertinoTextField(
                controller: widget.controller,
                padding: const EdgeInsets.all(12),
                minLines: 4,
                maxLines: 4,
                placeholder: 'Describe las tareas realizadas...',
                onChanged: (_) => _scheduleAutosave(),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
              )
            : TextField(
                controller: widget.controller,
                expands: false,
                minLines: 4,
                maxLines: 4,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => _scheduleAutosave(),
                decoration: InputDecoration(
                  hintText: 'Describe las tareas realizadas...',
                  filled: true,
                  fillColor: AppColors.surfaceHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (widget.onDelete != null)
              Expanded(
                child: isCupertino
                    ? CupertinoButton(
                        onPressed: () {
                          _stopDictation();
                          widget.onDelete!();
                          _lastSavedText = '';
                        },
                        color: AppColors.surfaceHighest,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Text(
                          'Borrar',
                          style: TextStyle(color: CupertinoColors.systemRed),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () {
                          _stopDictation();
                          widget.onDelete!();
                          _lastSavedText = '';
                        },
                        icon: const Icon(Icons.delete_rounded, size: 16),
                        label: const Text('Borrar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
              ),
            if (widget.onDelete != null) const SizedBox(width: 8),
            Expanded(
              child: isCupertino
                  ? CupertinoButton(
                      onPressed: _toggleDictation,
                      color: _isListening ? const Color(0xFFD94343) : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isListening ? CupertinoIcons.mic_slash_fill : CupertinoIcons.mic_fill,
                            size: 18,
                            color: AppColors.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _isListening ? 'Detener Dictado' : 'Dictado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.onPrimary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: _toggleDictation,
                      icon: Icon(
                        _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                        size: 20,
                      ),
                      label: Text(_isListening ? 'Detener Dictado' : 'Dictado'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: _isListening ? const Color(0xFFD94343) : AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
