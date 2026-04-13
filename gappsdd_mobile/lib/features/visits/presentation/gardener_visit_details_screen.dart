import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../auth/domain/auth_state.dart';
import '../../chat/domain/chat_models.dart';
import '../../chat/presentation/chat_with_request_modes_screen.dart';
import '../data/location_tracker.dart';
import '../domain/client_visits_data.dart';
import 'widgets/activity_gallery.dart';
import 'widgets/client_card.dart';
import 'widgets/notes_dictate_section.dart';
import 'widgets/timer_controls_card.dart';
import 'widgets/timestamp_edit_dialog.dart';

class GardenerVisitDetailsScreen extends ConsumerStatefulWidget {
  const GardenerVisitDetailsScreen({
    super.key,
    required this.garden,
    this.selectedVisitId,
  });

  final AssignedGardenVisitStatus garden;
  final String? selectedVisitId;

  @override
  ConsumerState<GardenerVisitDetailsScreen> createState() => _GardenerVisitDetailsScreenState();
}

class _GardenerVisitDetailsScreenState extends ConsumerState<GardenerVisitDetailsScreen> {
  late CommentController _commentController;
  ActiveVisitSnapshot? _visit;
  bool _isLoading = true;
  LocationTracker? _locationTracker;

  @override
  void initState() {
    super.initState();
    _commentController = CommentController();
    _loadVisit();
  }

  @override
  void dispose() {
    _locationTracker?.stop();
    _commentController.dispose();
    super.dispose();
  }

  bool get _isCupertino => Theme.of(context).platform == TargetPlatform.iOS;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    if (_isCupertino) {
      final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: confirmLabel.toLowerCase().contains('eliminar'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      );
      return result ?? false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _loadVisit() async {
    try {
      final visit = widget.selectedVisitId != null
          ? await ref.read(visitsRepositoryProvider).openCompletedVisitForEditing(
              visitId: widget.selectedVisitId!,
            )
          : await ref.read(visitsRepositoryProvider).loadActiveVisit();

      if (mounted) {
        setState(() {
          _visit = visit;
          _isLoading = false;
          if (visit != null) {
            _commentController.text = visit.publicComment;
          }
        });
      }

      // Start location tracker only for new active visits with a known DB id.
      if (visit != null && visit.isActive && visit.id != null && _locationTracker == null) {
        _startLocationTracker(visit.id!);
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

  void _startLocationTracker(String visitId) {
    _locationTracker = LocationTracker(
      onPoint: (lat, lng, accuracy) {
        ref.read(visitsRepositoryProvider).recordLocationPoint(
          visitId: visitId,
          lat: lat,
          lng: lng,
          accuracy: accuracy,
        );
      },
    );
    _locationTracker!.start();
  }

  Future<void> _closeVisit() async {
    HapticFeedback.mediumImpact();
    final shouldClose = await _confirmAction(
      title: '¿Cerrar visita?',
      message: 'La visita pasará a estado cerrada.',
      confirmLabel: 'Cerrar visita',
    );

    if (!shouldClose || !mounted) {
      return;
    }

    try {
      await ref.read(visitsRepositoryProvider).closeActiveVisit();
      _locationTracker?.stop();
      _locationTracker = null;
      await _loadVisit();
      if (!mounted) {
        return;
      }

      _showMessage('Visita cerrada correctamente');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error cerrando visita: $e');
    }
  }

  Future<void> _addPhoto() async {
    HapticFeedback.mediumImpact();
    if (!mounted) return;

    final source = await _pickImageSource();
    if (source == null) return;

    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final isCamera = source == ImageSource.camera;
      if (e.code == 'camera_access_denied') {
        _showMessage('Permiso de cámara denegado. Actívalo en Ajustes.');
      } else if (isCamera) {
        _showMessage('Cámara no disponible en este dispositivo.');
      } else {
        _showMessage('No se pudo acceder a la galería.');
      }
      return;
    }

    if (file == null || !mounted) return;

    try {
      await ref.read(visitsRepositoryProvider).addPhotoToActiveVisit(
        photoLabel: '',
        localPath: file.path,
        thumbnailPath: file.path,
      );

      await _loadVisit();
      if (!mounted) return;

      _showMessage('Foto añadida correctamente');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error añadiendo foto: $e');
    }
  }

  void _showPhotoFullScreen(LocalVisitPhoto photo) {
    final path = photo.localPath.isNotEmpty ? photo.localPath : photo.thumbnailPath;
    final isNetwork = path.startsWith('http');

    Widget imageWidget = isNetwork
        ? Image.network(
            path,
            fit: BoxFit.contain,
            errorBuilder: (context, err, stack) => const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
            ),
          )
        : Image.file(File(path), fit: BoxFit.contain);

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: imageWidget,
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<ImageSource?> _pickImageSource() {
    if (_isCupertino) {
      return showCupertinoModalPopup<ImageSource>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: const Text('Tomar foto'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: const Text('Elegir de la galería'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
      );
    }

    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removePhoto(String photoId) async {
    HapticFeedback.mediumImpact();
    final confirm = await _confirmAction(
      title: '¿Eliminar foto?',
      message: 'No se puede deshacer esta acción.',
      confirmLabel: 'Eliminar',
    );

    if (!confirm || !mounted) {
      return;
    }

    try {
      await ref.read(visitsRepositoryProvider).removePhotoFromActiveVisit(photoId: photoId);
      await _loadVisit();
      if (!mounted) {
        return;
      }

      _showMessage('Foto eliminada');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error eliminando foto: $e');
    }
  }

  Future<void> _saveComment() async {
    final comment = _commentController.text.trim();

    try {
      await ref.read(visitsRepositoryProvider).updatePublicComment(comment: comment);
      await _loadVisit();
      if (!mounted) {
        return;
      }

      _showMessage('Comentario guardado');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error guardando comentario: $e');
    }
  }

  Future<void> _deleteComment() async {
    final confirm = await _confirmAction(
      title: '¿Eliminar comentario?',
      message: 'No se puede deshacer esta acción.',
      confirmLabel: 'Eliminar',
    );

    if (!confirm || !mounted) {
      return;
    }

    try {
      await ref.read(visitsRepositoryProvider).updatePublicComment(comment: '');
      await _loadVisit();
      if (!mounted) {
        return;
      }

      _commentController.clear();
      _showMessage('Comentario eliminado');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error eliminando comentario: $e');
    }
  }

  Future<void> _editTimestamps() async {
    if (_visit == null || _visit!.isActive) {
      _showMessage('Solo se pueden editar timestamps en visitas cerradas');
      return;
    }

    final result = await showDialog<({DateTime start, DateTime end})>(
      context: context,
      builder: (context) => TimestampEditDialog(
        initialStart: _visit!.startedAt,
        initialEnd: _visit!.endedAt!,
        isCupertino: _isCupertino,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      await ref.read(visitsRepositoryProvider).updateVisitTimestamps(
        newStartTime: result.start,
        newEndTime: result.end,
      );

      await _loadVisit();
      if (!mounted) {
        return;
      }

      _showMessage('Horarios actualizados');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error actualizando horarios: $e');
    }
  }

  Future<void> _openChatWithClient() async {
    final chatRepository = ref.read(chatRepositoryProvider);
    final auth = ref.read(authProvider);
    final userId = auth?.userId ?? 'gardener-001';

    try {
      final conversations = await chatRepository.loadConversations(
        userId: userId,
        limit: 20,
      );

      final matchingConversation = conversations.where((conversation) {
        return conversation.otherUserId == 'client-001';
      });

      final fallbackId = widget.selectedVisitId != null
          ? 'conv-${widget.selectedVisitId}'
          : 'conv-${widget.garden.id}';
      final conversationId = matchingConversation.isNotEmpty
          ? matchingConversation.first.conversationId
          : fallbackId;

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatWithRequestModesScreen(
            repository: chatRepository,
            conversationId: conversationId,
            currentUserId: userId,
            currentUserRole: MessageRole.gardener,
          ),
        ),
      );
    } catch (e) {
      _showMessage('No se pudo abrir el chat: $e');
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
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      _isCupertino ? CupertinoIcons.back : Icons.arrow_back_rounded,
                    ),
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
              child: ClientCard(
                garden: widget.garden,
                onMessageTap: _openChatWithClient,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TimerControlsCard(
                visit: _visit!,
                onEditTimestamps: !_visit!.isActive ? _editTimestamps : null,
                onQrExit: _visit!.isActive ? _closeVisit : null,
                onManualExit: _visit!.isActive ? _closeVisit : null,
              ),
            ),
            if (widget.selectedVisitId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.visitHeatmap, extra: widget.selectedVisitId),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Mapa de Actividad'),
                  ),
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
              child: NotesDictateSection(
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
              child: ActivityGallery(
                photos: _visit!.photos,
                onAddPhoto: _addPhoto,
                onRemovePhoto: _removePhoto,
                onPhotoTap: _showPhotoFullScreen,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
