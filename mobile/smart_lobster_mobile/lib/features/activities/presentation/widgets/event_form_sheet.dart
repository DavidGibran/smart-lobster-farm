import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../models/farm_event_type.dart';
import '../farm_event_ui.dart';

typedef EventSubmitter =
    Future<void> Function({
      required FarmEventType type,
      required DateTime timestamp,
      String? note,
      String? cellId,
      Map<String, dynamic>? metadata,
    });

class EventFormSheet extends StatefulWidget {
  const EventFormSheet({super.key, required this.type, required this.onSubmit});

  final FarmEventType type;
  final EventSubmitter onSubmit;

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _cellController = TextEditingController();
  final _specificValueController = TextEditingController();

  late DateTime _timestamp;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _timestamp = DateTime.now();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _cellController.dispose();
    _specificValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Icon(
                        widget.type.icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.type.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Tanggal dan waktu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          DateFormat('dd MMM yyyy', 'id_ID').format(_timestamp),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickTime,
                        icon: const Icon(Icons.schedule_outlined),
                        label: Text(
                          DateFormat('HH:mm', 'id_ID').format(_timestamp),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const ValueKey('event-cell-id'),
                  controller: _cellController,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'ID Apartemen / Cell (opsional)',
                    hintText: 'Contoh: A-07',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_specificFieldConfig() case final config?) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const ValueKey('event-specific-value'),
                    controller: _specificValueController,
                    enabled: !_isSubmitting,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: '${config.label} (opsional)',
                      suffixText: config.unit,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        _validateSpecificValue(value, maximum: config.maximum),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const ValueKey('event-note'),
                  controller: _noteController,
                  enabled: !_isSubmitting,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('event-save'),
                    onPressed: _isSubmitting ? null : _save,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSubmitting ? 'Menyimpan...' : 'Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    setState(() {
      _timestamp = DateTime(
        date.year,
        date.month,
        date.day,
        _timestamp.hour,
        _timestamp.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time == null || !mounted) return;
    setState(() {
      _timestamp = DateTime(
        _timestamp.year,
        _timestamp.month,
        _timestamp.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(
        type: widget.type,
        timestamp: _timestamp,
        note: _optionalText(_noteController.text),
        cellId: _optionalText(_cellController.text),
        metadata: _metadata(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Gagal menyimpan aktivitas';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan aktivitas')),
      );
    }
  }

  String? _validateSpecificValue(String? value, {double? maximum}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = double.tryParse(text.replaceAll(',', '.'));
    if (number == null || number <= 0) return 'Masukkan angka lebih dari 0';
    if (maximum != null && number > maximum) {
      return 'Nilai maksimal ${maximum.toStringAsFixed(0)}';
    }
    return null;
  }

  Map<String, dynamic>? _metadata() {
    final config = _specificFieldConfig();
    final rawValue = _specificValueController.text.trim();
    if (config == null || rawValue.isEmpty) return null;
    final value = double.parse(rawValue.replaceAll(',', '.'));
    return {config.key: value == value.roundToDouble() ? value.toInt() : value};
  }

  _SpecificFieldConfig? _specificFieldConfig() {
    return switch (widget.type) {
      FarmEventType.feeding => const _SpecificFieldConfig(
        key: 'amount_gram',
        label: 'Jumlah pakan',
        unit: 'gram',
      ),
      FarmEventType.waterChange => const _SpecificFieldConfig(
        key: 'percentage',
        label: 'Persentase air',
        unit: '%',
        maximum: 100,
      ),
      FarmEventType.waterAddition => const _SpecificFieldConfig(
        key: 'volume_liter',
        label: 'Volume air',
        unit: 'liter',
      ),
      _ => null,
    };
  }

  String? _optionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}

class _SpecificFieldConfig {
  const _SpecificFieldConfig({
    required this.key,
    required this.label,
    required this.unit,
    this.maximum,
  });

  final String key;
  final String label;
  final String unit;
  final double? maximum;
}
