import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/animal.dart';
import '../services/animal_service.dart';
import '../utils/theme.dart';
import '../widgets/enhanced_back_button.dart';

class CarcassMeasurementScreen extends StatefulWidget {
  final Animal animal;

  const CarcassMeasurementScreen({super.key, required this.animal});

  @override
  State<CarcassMeasurementScreen> createState() => _CarcassMeasurementScreenState();
}

class _CarcassMeasurementScreenState extends State<CarcassMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _units = {};
  final bool _isLoading = false;
  bool _isSubmitting = false;

  // Default measurement fields
  final List<String> _defaultFields = ['head_weight', 'torso_weight', 'leg_weight'];

  // Custom fields that can be added
  final List<String> _customFields = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize default fields
    for (final field in _defaultFields) {
      _controllers[field] = TextEditingController();
      _units[field] = 'kg';
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addCustomField() {
    final TextEditingController fieldController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Measurement'),
        content: TextField(
          controller: fieldController,
          decoration: const InputDecoration(
            labelText: 'Field Name',
            hintText: 'e.g., organ_weight, hide_dimensions',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final fieldName = fieldController.text.trim().toLowerCase().replaceAll(' ', '_');
              if (fieldName.isNotEmpty && !_controllers.containsKey(fieldName)) {
                setState(() {
                  _customFields.add(fieldName);
                  _controllers[fieldName] = TextEditingController();
                  _units[fieldName] = 'kg';
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeCustomField(String fieldName) {
    setState(() {
      _customFields.remove(fieldName);
      _controllers[fieldName]?.dispose();
      _controllers.remove(fieldName);
      _units.remove(fieldName);
    });
  }

  Future<void> _submitMeasurements() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final measurements = <String, Map<String, dynamic>>{};

      for (final entry in _controllers.entries) {
        final fieldName = entry.key;
        final controller = entry.value;
        final unit = _units[fieldName]!;

        if (controller.text.isNotEmpty) {
          final value = double.tryParse(controller.text);
          if (value != null) {
            measurements[fieldName] = {'value': value, 'unit': unit};
          }
        }
      }

      if (measurements.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one measurement'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }

      final carcassMeasurement = CarcassMeasurement(
        animalId: widget.animal.id!,
        measurements: measurements,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final animalService = AnimalService();
      await animalService.createCarcassMeasurement(carcassMeasurement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Carcass measurements saved successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        context.go('/farmer-home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save measurements: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildMeasurementField(String fieldName, {bool isCustom = false}) {
    final displayName = fieldName.replaceAll('_', ' ').toUpperCase();
    final controller = _controllers[fieldName]!;
    final unit = _units[fieldName]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCustom)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                    onPressed: () => _removeCustomField(fieldName),
                    tooltip: 'Remove field',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Value',
                      hintText: 'Enter measurement value',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final numValue = double.tryParse(value);
                        if (numValue == null) {
                          return 'Please enter a valid number';
                        }
                        if (numValue <= 0) {
                          return 'Value must be greater than 0';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: unit,
                  items: ['kg', 'lbs', 'g'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _units[fieldName] = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBarWithBackButton(
        title: 'Carcass Measurements',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Record Carcass Measurements',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Animal: ${widget.animal.species} ${widget.animal.animalId}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'Please record the measurements from the slaughtered animal\'s carcass. All measurements are optional but at least one is required.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Default measurement fields
                    Text(
                      'Standard Measurements',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._defaultFields.map((field) => _buildMeasurementField(field)),

                    const SizedBox(height: 24),

                    // Custom measurement fields
                    if (_customFields.isNotEmpty) ...[
                      Text(
                        'Custom Measurements',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._customFields.map((field) => _buildMeasurementField(field, isCustom: true)),
                      const SizedBox(height: 12),
                    ],

                    // Add custom field button
                    OutlinedButton.icon(
                      onPressed: _addCustomField,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom Measurement'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitMeasurements,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Measurements'),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}







