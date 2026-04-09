import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class TimestampEditDialog extends StatefulWidget {
  const TimestampEditDialog({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.isCupertino,
  });

  final DateTime initialStart;
  final DateTime initialEnd;
  final bool isCupertino;

  @override
  State<TimestampEditDialog> createState() => _TimestampEditDialogState();
}

class _TimestampEditDialogState extends State<TimestampEditDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.fromDateTime(widget.initialStart);
    _endTime = TimeOfDay.fromDateTime(widget.initialEnd);
  }

  Future<void> _pickStartTime() async {
    if (widget.isCupertino) {
      final picked = await _pickTimeCupertino(_startTime);
      if (picked != null) {
        setState(() => _startTime = picked);
      }
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    if (widget.isCupertino) {
      final picked = await _pickTimeCupertino(_endTime);
      if (picked != null) {
        setState(() => _endTime = picked);
      }
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<TimeOfDay?> _pickTimeCupertino(TimeOfDay initial) async {
    DateTime selected = DateTime(
      widget.initialStart.year,
      widget.initialStart.month,
      widget.initialStart.day,
      initial.hour,
      initial.minute,
    );

    final result = await showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (context) {
        return Container(
          height: 280,
          color: AppColors.surface,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () {
                    Navigator.of(context).pop(TimeOfDay.fromDateTime(selected));
                  },
                  child: const Text('Listo'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: selected,
                  use24hFormat: true,
                  onDateTimeChanged: (value) {
                    selected = value;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    return result;
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

    void save() {
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
    }

    if (widget.isCupertino) {
      return CupertinoAlertDialog(
        title: const Text('Editar Horarios'),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              CupertinoButton(
                onPressed: _pickStartTime,
                padding: EdgeInsets.zero,
                child: Text('Entrada: ${_startTime.format(context)}'),
              ),
              CupertinoButton(
                onPressed: _pickEndTime,
                padding: EdgeInsets.zero,
                child: Text('Salida: ${_endTime.format(context)}'),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            onPressed: save,
            child: const Text('Guardar'),
          ),
        ],
      );
    }

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
          onPressed: save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
