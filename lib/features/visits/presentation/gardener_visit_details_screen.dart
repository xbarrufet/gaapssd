import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../app/theme/app_theme.dart';
import '../data/visits_repository.dart';
import '../domain/client_visits_data.dart';

class GardenerVisitDetailsScreen extends StatefulWidget {
  const GardenerVisitDetailsScreen({
    super.key,
    required this.garden,
    required this.repository,
  });

  final AssignedGardenVisitStatus garden;
  final VisitsRepository repository;

  @override
  State<GardenerVisitDetailsScreen> createState() => _GardenerVisitDetailsScreenState();
}

class _GardenerVisitDetailsScreenState extends State<GardenerVisitDetailsScreen> {
  late CommentController _commentController;
  ActiveVisitSnapshot? _visit;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _commentController = CommentController();
    _loadActiveVisit();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveVisit() async {
    try {
      final visit = await widget.repository.loadActiveVisit();
      if (mounted) {
        setState(() {
          _visit = visit;
          _isLoading = false;
          if (visit != null) {
            _commentController.text = visit.publicComment;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando visita: $e')),
        );
      }
    }
  }

  Future<void> _closeVisit() async {
    final shouldClose = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('¿Cerrar visita?'),
              content: const Text('La visita pasará a estado cerrada.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Cerrar visita'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldClose || !mounted) {
      return;
    }

    try {
      await widget.repository.closeActiveVisit();
      await _loadActiveVisit();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita cerrada correctamente')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cerrando visita: $e')),
      );
    }
  }

  Future<void> _addPhoto() async {
    if (!mounted) {
      return;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final localPath = 'local/photos/photo-$timestamp.jpg';
      const thumbnailPath = 'local/photos/thumb.jpg';

      await widget.repository.addPhotoToActiveVisit(
        photoLabel: '',
        localPath: localPath,
        thumbnailPath: thumbnailPath,
      );

      await _loadActiveVisit();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto añadida correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error añadiendo foto: $e')),
      );
    }
  }

  Future<void> _removePhoto(String photoId) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('¿Eliminar foto?'),
              content: const Text('No se puede deshacer esta acción.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm || !mounted) {
      return;
    }

    try {
      await widget.repository.removePhotoFromActiveVisit(photoId: photoId);
      await _loadActiveVisit();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto eliminada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando foto: $e')),
      );
    }
  }

  Future<void> _saveComment() async {
    final comment = _commentController.text.trim();

    try {
      await widget.repository.updatePublicComment(comment: comment);
      await _loadActiveVisit();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentario guardado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando comentario: $e')),
      );
    }
  }

  Future<void> _deleteComment() async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('¿Eliminar comentario?'),
              content: const Text('No se puede deshacer esta acción.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm || !mounted) {
      return;
    }

    try {
      await widget.repository.updatePublicComment(comment: '');
      await _loadActiveVisit();
      if (!mounted) {
        return;
      }

      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentario eliminado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando comentario: $e')),
      );
    }
  }

  Future<void> _editTimestamps() async {
    if (_visit == null || _visit!.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo se pueden editar timestamps en visitas cerradas')),
      );
      return;
    }

    final result = await showDialog<({DateTime start, DateTime end})>(
      context: context,
      builder: (context) => _TimestampEditDialog(
        initialStart: _visit!.startedAt,
        initialEnd: _visit!.endedAt!,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      await widget.repository.updateVisitTimestamps(
        newStartTime: result.start,
        newEndTime: result.end,
      );

      await _loadActiveVisit();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horarios actualizados')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error actualizando horarios: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_visit == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No hay visita activa'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.primary,
                  ),
                  Text(
                    'Detalles de Visita',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ClientCard(garden: widget.garden),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _TimerControlsCard(
                visit: _visit!,
                onEditTimestamps: !_visit!.isActive ? _editTimestamps : null,
                onQrExit: _visit!.isActive ? _closeVisit : null,
                onManualExit: _visit!.isActive ? _closeVisit : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Notas y Comentarios',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _NotesDictateSection(
                controller: _commentController,
                onSave: _saveComment,
                onDelete: _visit!.publicComment.isNotEmpty ? _deleteComment : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Fotos del Trabajo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ActivityGallery(
                photos: _visit!.photos,
                onAddPhoto: _addPhoto,
                onRemovePhoto: _removePhoto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.garden});

  final AssignedGardenVisitStatus garden;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JARDÍN ACTUAL',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      garden.gardenName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(garden.address, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                ),
                icon: const Icon(Icons.call_rounded),
                color: AppColors.onPrimary,
              ),
            ],
          ),
          Positioned(
            right: -14,
            bottom: -22,
            child: Icon(
              Icons.park_rounded,
              size: 84,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerControlsCard extends StatelessWidget {
  const _TimerControlsCard({
    required this.visit,
    this.onEditTimestamps,
    this.onQrExit,
    this.onManualExit,
  });

  final ActiveVisitSnapshot visit;
  final VoidCallback? onEditTimestamps;
  final VoidCallback? onQrExit;
  final VoidCallback? onManualExit;

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildEditableTimeBox({
    required BuildContext context,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.primaryContainer.withValues(alpha: 0.25)
                : AppColors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isEnabled
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.outline.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final durationStr = visit.duration != null ? _formatDuration(visit.duration!) : '00:00:00';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ENTRADA', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    _buildEditableTimeBox(
                      context: context,
                      value: _formatTime(visit.startedAt),
                      icon: Icons.login_rounded,
                      onTap: onEditTimestamps,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      visit.isActive ? 'DURACIÓN EN VIVO' : 'DURACIÓN TOTAL',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durationStr,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (visit.endedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SALIDA', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 6),
                        _buildEditableTimeBox(
                          context: context,
                          value: _formatTime(visit.endedAt!),
                          icon: Icons.logout_rounded,
                          onTap: onEditTimestamps,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('ESTADO', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: visit.isVerified ? const Color(0xFF4CAF50).withValues(alpha: 0.2) : const Color(0xFFF44336).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            visit.isVerified ? 'Verificada' : 'No Verificada',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: visit.isVerified ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (visit.isActive && onManualExit != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onQrExit,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(
                      'ESCANEAR QR SALIDA',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 10,
                          ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManualExit,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(
                      'SALIDA MANUAL',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 10),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.outline.withValues(alpha: 0.35)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityGallery extends StatelessWidget {
  const _ActivityGallery({
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final List<LocalVisitPhoto> photos;
  final VoidCallback onAddPhoto;
  final Function(String) onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (photos.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.image_not_supported_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin fotos aún',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _PhotoTile(
                photo: photo,
                onRemove: () => onRemovePhoto(photo.id),
              );
            },
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAddPhoto,
            icon: const Icon(Icons.photo_camera_rounded),
            label: Text(
              'AÑADIR FOTO',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.secondary,
                    fontSize: 11,
                  ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD6EAB6),
              foregroundColor: AppColors.secondary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.onRemove,
  });

  final LocalVisitPhoto photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            color: AppColors.surfaceHigh,
            child: Center(
              child: Icon(
                Icons.image_rounded,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommentController extends TextEditingController {}

class _NotesDictateSection extends StatefulWidget {
  const _NotesDictateSection({
    required this.controller,
    required this.onSave,
    this.onDelete,
  });

  final TextEditingController controller;
  final Future<void> Function() onSave;
  final VoidCallback? onDelete;

  @override
  State<_NotesDictateSection> createState() => _NotesDictateSectionState();
}

class _NotesDictateSectionState extends State<_NotesDictateSection> {
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
    unawaited(_flushSave(force: true));
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
        const SnackBar(content: Text('El dictado no está disponible en este dispositivo')),
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
    return Column(
      children: [
        TextField(
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
                child: OutlinedButton.icon(
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
              child: FilledButton.icon(
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

class _TimestampEditDialog extends StatefulWidget {
  const _TimestampEditDialog({
    required this.initialStart,
    required this.initialEnd,
  });

  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<_TimestampEditDialog> createState() => _TimestampEditDialogState();
}

class _TimestampEditDialogState extends State<_TimestampEditDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.fromDateTime(widget.initialStart);
    _endTime = TimeOfDay.fromDateTime(widget.initialEnd);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final newStart = DateTime(
      widget.initialStart.year,
      widget.initialStart.month,
      widget.initialStart.day,
      _startTime.hour,
      _startTime.minute,
    );
    final newEnd = DateTime(
      widget.initialEnd.year,
      widget.initialEnd.month,
      widget.initialEnd.day,
      _endTime.hour,
      _endTime.minute,
    );

    return AlertDialog(
      title: const Text('Editar Horarios'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Entrada'),
            subtitle: Text(_startTime.format(context)),
            trailing: const Icon(Icons.access_time_rounded),
            onTap: _pickStartTime,
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Salida'),
            subtitle: Text(_endTime.format(context)),
            trailing: const Icon(Icons.access_time_rounded),
            onTap: _pickEndTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (newEnd.isBefore(newStart)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('La salida no puede ser antes de la entrada')),
              );
              return;
            }

            final diff = newStart.difference(widget.initialStart).abs();
            if (diff.inHours > 24) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Los horarios deben estar dentro de 24 horas')),
              );
              return;
            }

            Navigator.of(context).pop((start: newStart, end: newEnd));
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}