import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/loading_button.dart';
import '../../../core/errors/app_error.dart';
import '../domain/client_visits_data.dart';

class NewVisitScreen extends ConsumerStatefulWidget {
  const NewVisitScreen({
    super.key,
  });

  @override
  ConsumerState<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends ConsumerState<NewVisitScreen> {
  bool get _isCupertino => Theme.of(context).platform == TargetPlatform.iOS;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkAndOpenActiveVisit() async {
    final activeVisit = await ref.read(visitsRepositoryProvider).loadActiveVisit();
    if (!mounted || activeVisit == null) {
      return;
    }

    _showMessage('Ya tienes una visita activa');

    await context.push(AppRoutes.gardenerVisitDetail, extra: {'garden': activeVisit.garden});
  }

  Future<void> _startVisitFromQrDemo() async {
    try {
      final repo = ref.read(visitsRepositoryProvider);
      final activeVisit = await repo.loadActiveVisit();
      if (activeVisit != null) {
        if (!mounted) {
          return;
        }
        _showMessage('Ya tienes una visita en progreso');
        await context.push(AppRoutes.gardenerVisitDetail, extra: {'garden': activeVisit.garden});
        return;
      }

      final assignedGardens = await repo.loadAssignedGardensVisitStatus();
      if (assignedGardens.isEmpty) {
        if (!mounted) {
          return;
        }
        _showMessage('No tienes jardines asignados');
        return;
      }

      final selectedGarden = await _pickGarden(
        title: 'Selecciona jardín para QR (demo)',
        gardens: assignedGardens,
      );

      if (selectedGarden == null || !mounted) {
        return;
      }

      final visit = await repo.startVisitFromQr(gardenId: selectedGarden.id);
      if (!mounted) {
        return;
      }

      context.pushReplacement(AppRoutes.gardenerVisitDetail, extra: {'garden': visit.garden});
    } on AppError catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
    }
  }

  Future<void> _startManualFlow() async {
    try {
      final repo = ref.read(visitsRepositoryProvider);
      final activeVisit = await repo.loadActiveVisit();
      if (activeVisit != null) {
        if (!mounted) {
          return;
        }
        _showMessage('Ya tienes una visita en progreso');
        await context.push(AppRoutes.gardenerVisitDetail, extra: {'garden': activeVisit.garden});
        return;
      }

      final mode = await _pickManualMode();
      if (mode == null) {
        return;
      }

      if (mode == _ManualStartMode.nearbySingle || mode == _ManualStartMode.nearbyMultiple) {
        final nearbyGardens = await repo.loadNearbyManualStartCandidates();
        if (nearbyGardens.isEmpty) {
          await _startManualFallback(isVerified: false);
          return;
        }

        if (mode == _ManualStartMode.nearbySingle) {
          final selected = nearbyGardens.first;
          final visit = await repo.startManualVisit(
            gardenId: selected.garden.id,
            isVerified: true,
          );
          if (!mounted) {
            return;
          }
          context.pushReplacement(AppRoutes.gardenerVisitDetail, extra: {'garden': visit.garden});
          return;
        }

        final selectedGarden = await _pickGarden(
          title: 'Jardines cercanos (<= 10m)',
          gardens: nearbyGardens
              .map((candidate) => AssignedGardenVisitStatus(
                    id: candidate.garden.id,
                    gardenName:
                        '${candidate.garden.gardenName} (${candidate.distanceMeters.toStringAsFixed(1)}m)',
                    address: candidate.garden.address,
                    urgency: candidate.garden.urgency,
                    lastVisitLabel: candidate.garden.lastVisitLabel,
                    lastVisitAge: candidate.garden.lastVisitAge,
                    evidence: candidate.garden.evidence,
                    primaryActionLabel: candidate.garden.primaryActionLabel,
                  ))
              .toList(),
        );

        if (selectedGarden == null) {
          return;
        }

        final visit = await repo.startManualVisit(
          gardenId: selectedGarden.id,
          isVerified: true,
        );
        if (!mounted) {
          return;
        }
        context.pushReplacement(AppRoutes.gardenerVisitDetail, extra: {'garden': visit.garden});
        return;
      }

      await _startManualFallback(isVerified: false);
    } on AppError catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
    }
  }

  Future<void> _startManualFallback({required bool isVerified}) async {
    final repo = ref.read(visitsRepositoryProvider);
    final assignedGardens = await repo.loadAssignedGardensVisitStatus();
    if (assignedGardens.isEmpty) {
      if (!mounted) {
        return;
      }
      _showMessage('No tienes jardines asignados');
      return;
    }

    final selected = await _pickGarden(
      title: 'Selecciona jardín asignado',
      gardens: assignedGardens,
    );

    if (selected == null) {
      return;
    }

    final visit = await repo.startManualVisit(
      gardenId: selected.id,
      isVerified: isVerified,
    );

    if (!mounted) {
      return;
    }

    context.pushReplacement(AppRoutes.gardenerVisitDetail, extra: {'garden': visit.garden});
  }

  Future<AssignedGardenVisitStatus?> _pickGarden({
    required String title,
    required List<AssignedGardenVisitStatus> gardens,
  }) {
    if (_isCupertino) {
      return showCupertinoModalPopup<AssignedGardenVisitStatus>(
        context: context,
        builder: (context) {
          return CupertinoActionSheet(
            title: Text(title),
            actions: [
              for (final garden in gardens)
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(context).pop(garden),
                  child: Column(
                    children: [
                      Text(garden.gardenName),
                      const SizedBox(height: 2),
                      Text(
                        garden.address,
                        style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                      ),
                    ],
                  ),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          );
        },
      );
    }

    return showModalBottomSheet<AssignedGardenVisitStatus>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: gardens.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final garden = gardens[index];
                    return ListTile(
                      title: Text(garden.gardenName),
                      subtitle: Text(garden.address),
                      onTap: () => Navigator.of(context).pop(garden),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_ManualStartMode?> _pickManualMode() {
    if (_isCupertino) {
      return showCupertinoModalPopup<_ManualStartMode>(
        context: context,
        builder: (context) {
          return CupertinoActionSheet(
            title: const Text('Inicio manual'),
            message: const Text('Selecciona el escenario de la demo'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(_ManualStartMode.nearbySingle),
                child: const Text('GPS: 1 jardín cercano (verificada)'),
              ),
              CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(_ManualStartMode.nearbyMultiple),
                child: const Text('GPS: varios jardines cercanos (verificada)'),
              ),
              CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(_ManualStartMode.fallbackNotVerified),
                child: const Text('GPS no disponible / sin candidatos (no verificada)'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          );
        },
      );
    }

    return showModalBottomSheet<_ManualStartMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.gps_fixed_rounded),
                title: const Text('GPS: 1 jardín cercano (verificada)'),
                onTap: () => Navigator.of(context).pop(_ManualStartMode.nearbySingle),
              ),
              ListTile(
                leading: const Icon(Icons.place_rounded),
                title: const Text('GPS: varios jardines cercanos (verificada)'),
                onTap: () => Navigator.of(context).pop(_ManualStartMode.nearbyMultiple),
              ),
              ListTile(
                leading: const Icon(Icons.location_off_rounded),
                title: const Text('GPS no disponible / sin candidatos (no verificada)'),
                onTap: () => Navigator.of(context).pop(_ManualStartMode.fallbackNotVerified),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = _isCupertino;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1D3325), Color(0xFF4B6A4F)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          isCupertino ? CupertinoIcons.back : Icons.arrow_back_rounded,
                        ),
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Text(
                          'Nueva Visita',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: _checkAndOpenActiveVisit,
                        icon: Icon(
                          isCupertino
                              ? CupertinoIcons.check_mark_circled
                              : Icons.assignment_turned_in_outlined,
                        ),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCupertino ? CupertinoIcons.qrcode_viewfinder : Icons.qr_code_scanner_rounded,
                              size: 92,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Apunta al QR del jardín',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'En esta versión se simula la lectura de QR',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                            ),
                            const SizedBox(height: 18),
                            LoadingButton(
                              onPressed: _startVisitFromQrDemo,
                              label: 'Escanear QR (Demo)',
                              icon: Icons.camera_alt_rounded,
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.onPrimary,
                              minimumSize: const Size(220, 54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: LoadingButton(
                    onPressed: _startManualFlow,
                    label: 'Inicio Manual',
                    icon: Icons.play_circle_fill_rounded,
                    backgroundColor: const Color(0xFFD6EAB6),
                    foregroundColor: AppColors.secondary,
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ManualStartMode {
  nearbySingle,
  nearbyMultiple,
  fallbackNotVerified,
}
