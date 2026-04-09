import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../data/visits_repository.dart';
import '../domain/client_visits_data.dart';
import 'gardener_visit_details_screen.dart';

class NewVisitScreen extends StatefulWidget {
  const NewVisitScreen({
    super.key,
    required this.repository,
  });

  final VisitsRepository repository;

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  bool _isBusy = false;

  Future<void> _checkAndOpenActiveVisit() async {
    final activeVisit = await widget.repository.loadActiveVisit();
    if (!mounted || activeVisit == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ya tienes una visita activa')),
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GardenerVisitDetailsScreen(
          garden: activeVisit.garden,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _startVisitFromQrDemo() async {
    if (_isBusy) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      final activeVisit = await widget.repository.loadActiveVisit();
      if (activeVisit != null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya tienes una visita en progreso')),
        );
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GardenerVisitDetailsScreen(
              garden: activeVisit.garden,
              repository: widget.repository,
            ),
          ),
        );
        return;
      }

      final assignedGardens = await widget.repository.loadAssignedGardensVisitStatus();
      if (assignedGardens.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes jardines asignados')),
        );
        return;
      }

      final selectedGarden = await _pickGarden(
        title: 'Selecciona jardín para QR (demo)',
        gardens: assignedGardens,
      );

      if (selectedGarden == null || !mounted) {
        return;
      }

      final visit = await widget.repository.startVisitFromQr(gardenId: selectedGarden.id);
      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GardenerVisitDetailsScreen(
            garden: visit.garden,
            repository: widget.repository,
          ),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'No se ha podido iniciar la visita')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _startManualFlow() async {
    if (_isBusy) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      final activeVisit = await widget.repository.loadActiveVisit();
      if (activeVisit != null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya tienes una visita en progreso')),
        );
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GardenerVisitDetailsScreen(
              garden: activeVisit.garden,
              repository: widget.repository,
            ),
          ),
        );
        return;
      }

      final mode = await _pickManualMode();
      if (mode == null) {
        return;
      }

      if (mode == _ManualStartMode.nearbySingle || mode == _ManualStartMode.nearbyMultiple) {
        final nearbyGardens = await widget.repository.loadNearbyManualStartCandidates();
        if (nearbyGardens.isEmpty) {
          await _startManualFallback(isVerified: false);
          return;
        }

        if (mode == _ManualStartMode.nearbySingle) {
          final selected = nearbyGardens.first;
          final visit = await widget.repository.startManualVisit(
            gardenId: selected.garden.id,
            isVerified: true,
          );
          if (!mounted) {
            return;
          }
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => GardenerVisitDetailsScreen(
                garden: visit.garden,
                repository: widget.repository,
              ),
            ),
          );
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

        final visit = await widget.repository.startManualVisit(
          gardenId: selectedGarden.id,
          isVerified: true,
        );
        if (!mounted) {
          return;
        }
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => GardenerVisitDetailsScreen(
              garden: visit.garden,
              repository: widget.repository,
            ),
          ),
        );
        return;
      }

      await _startManualFallback(isVerified: false);
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'No se ha podido iniciar la visita')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _startManualFallback({required bool isVerified}) async {
    final assignedGardens = await widget.repository.loadAssignedGardensVisitStatus();
    if (assignedGardens.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes jardines asignados')),
      );
      return;
    }

    final selected = await _pickGarden(
      title: 'Selecciona jardín asignado',
      gardens: assignedGardens,
    );

    if (selected == null) {
      return;
    }

    final visit = await widget.repository.startManualVisit(
      gardenId: selected.id,
      isVerified: isVerified,
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GardenerVisitDetailsScreen(
          garden: visit.garden,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<AssignedGardenVisitStatus?> _pickGarden({
    required String title,
    required List<AssignedGardenVisitStatus> gardens,
  }) {
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
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
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
                        icon: const Icon(Icons.assignment_turned_in_outlined),
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
                            const Icon(Icons.qr_code_scanner_rounded, size: 92, color: Colors.white),
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
                            FilledButton.icon(
                              onPressed: _isBusy ? null : _startVisitFromQrDemo,
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text('Escanear QR (Demo)'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: AppColors.onPrimary,
                                minimumSize: const Size(220, 54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: FilledButton.icon(
                    onPressed: _isBusy ? null : _startManualFlow,
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: const Text('Inicio Manual'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: const Color(0xFFD6EAB6),
                      foregroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isBusy)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
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
