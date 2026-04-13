import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/widgets/loading_button.dart';
import '../../../core/errors/app_error.dart';
import '../domain/client_visits_data.dart';

class NewVisitScreen extends ConsumerStatefulWidget {
  const NewVisitScreen({super.key});

  @override
  ConsumerState<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends ConsumerState<NewVisitScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _isProcessing = false;
  bool get _isCupertino => Theme.of(context).platform == TargetPlatform.iOS;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidUuid(String value) {
    const uuidPattern =
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
    return RegExp(uuidPattern).hasMatch(value);
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    if (!_isValidUuid(rawValue)) {
      _showMessage('QR inválido, intenta de nuevo');
      return;
    }

    setState(() => _isProcessing = true);
    await _scannerController.stop();

    try {
      final repo = ref.read(visitsRepositoryProvider);

      final activeVisit = await repo.loadActiveVisit();
      if (activeVisit != null) {
        if (!mounted) return;
        _showMessage('Ya tienes una visita en progreso');
        await context.push(AppRoutes.gardenerVisitDetail, extra: {'garden': activeVisit.garden});
        return;
      }

      final visit = await repo.startVisitFromQr(gardenId: rawValue);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.gardenerVisitDetail, extra: {'garden': visit.garden});
    } on AppError catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
      setState(() => _isProcessing = false);
      await _scannerController.start();
    }
  }

  Future<void> _startManualFlow() async {
    try {
      final repo = ref.read(visitsRepositoryProvider);
      final activeVisit = await repo.loadActiveVisit();
      if (activeVisit != null) {
        if (!mounted) return;
        _showMessage('Ya tienes una visita en progreso');
        await context.push(AppRoutes.gardenerVisitDetail, extra: {'garden': activeVisit.garden});
        return;
      }

      final mode = await _pickManualMode();
      if (mode == null) return;

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
          if (!mounted) return;
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

        if (selectedGarden == null) return;

        final visit = await repo.startManualVisit(
          gardenId: selectedGarden.id,
          isVerified: true,
        );
        if (!mounted) return;
        context.pushReplacement(AppRoutes.gardenerVisitDetail, extra: {'garden': visit.garden});
        return;
      }

      await _startManualFallback(isVerified: false);
    } on AppError catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    }
  }

  Future<void> _startManualFallback({required bool isVerified}) async {
    final repo = ref.read(visitsRepositoryProvider);
    final assignedGardens = await repo.loadAssignedGardensVisitStatus();
    if (assignedGardens.isEmpty) {
      if (!mounted) return;
      _showMessage('No tienes jardines asignados');
      return;
    }

    final selected = await _pickGarden(
      title: 'Selecciona jardín asignado',
      gardens: assignedGardens,
    );

    if (selected == null) return;

    final visit = await repo.startManualVisit(
      gardenId: selected.id,
      isVerified: isVerified,
    );

    if (!mounted) return;
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
          // Camera preview — full screen
          MobileScanner(
            controller: _scannerController,
            onDetect: _onQrDetected,
          ),

          // Dark overlay at top for header readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC1D3325), Colors.transparent],
                ),
              ),
            ),
          ),

          // Dark overlay at bottom for button readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xDD1D3325), Colors.transparent],
                ),
              ),
            ),
          ),

          // Scanning frame overlay
          Center(
            child: _ScanFrame(isProcessing: _isProcessing),
          ),

          // UI controls
          SafeArea(
            child: Column(
              children: [
                // Header
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
                      // Spacer to keep title centered
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(),

                // Scan hint
                if (!_isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Apunta al QR del jardín',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ),

                // Manual start button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: LoadingButton(
                    onPressed: _startManualFlow,
                    label: 'Inicio Manual',
                    icon: Icons.play_circle_fill_rounded,
                    backgroundColor: const Color(0xFFD6EAB6),
                    foregroundColor: const Color(0xFF1D3325),
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

/// Animated scanning frame shown in the center of the camera preview.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.isProcessing});

  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(
              color: isProcessing
                  ? Colors.green.shade300
                  : Colors.white.withValues(alpha: 0.8),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: isProcessing
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : null,
        ),
      ],
    );
  }
}

enum _ManualStartMode {
  nearbySingle,
  nearbyMultiple,
  fallbackNotVerified,
}
