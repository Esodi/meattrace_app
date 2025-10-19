import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/animal.dart';
import '../../providers/animal_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../widgets/core/custom_text_field.dart';

/// Register Animal Screen - Modern UI following design system
/// Based on DESIGN_SCREENS_LAYOUTS.md specifications
class RegisterAnimalScreen extends StatefulWidget {
  const RegisterAnimalScreen({Key? key}) : super(key: key);

  @override
  State<RegisterAnimalScreen> createState() => _RegisterAnimalScreenState();
}

class _RegisterAnimalScreenState extends State<RegisterAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  
  // Form controllers
  final _tagIdController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _abbatoirController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Form state
  String? _selectedSpecies;
  DateTime _selectedDate = DateTime.now();
  double _weightValue = 50;
  String _selectedGender = 'male';
  String _selectedHealthStatus = 'healthy';
  File? _selectedImage;
  bool _isLoading = false;

  // Species options with icons - values must match backend choices
  final List<Map<String, dynamic>> _speciesOptions = [
    {'value': 'cow', 'label': 'Cattle (Cow/Bull)', 'icon': '🐄'},
    {'value': 'pig', 'label': 'Pig', 'icon': '🐷'},
    {'value': 'chicken', 'label': 'Chicken', 'icon': '🐔'},
    {'value': 'sheep', 'label': 'Sheep', 'icon': '🐑'},
    {'value': 'goat', 'label': 'Goat', 'icon': '🐐'},
  ];

  @override
  void initState() {
    super.initState();
    _generateTagId();
  }

  @override
  void dispose() {
    _tagIdController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _abbatoirController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generateTagId() {
    final now = DateTime.now();
    final species = _selectedSpecies?.toUpperCase() ?? 'ANIMAL';
    final year = now.year;
    final random = now.millisecondsSinceEpoch % 1000;
    _tagIdController.text = '$species-$year-${random.toString().padLeft(3, '0')}';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.farmerPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Photo',
                style: AppTypography.titleLarge(),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.farmerPrimary),
                title: Text('Take Photo', style: AppTypography.bodyLarge()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.farmerPrimary),
                title: Text('Choose from Gallery', style: AppTypography.bodyLarge()),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerAnimal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSpecies == null) {
      _showErrorSnackbar('Please select a species');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final animalProvider = context.read<AnimalProvider>();
      
      // Calculate age in months from birth date
      final now = DateTime.now();
      final ageInMonths = ((now.difference(_selectedDate).inDays) / 30.44).round(); // More accurate month calculation
      
      // Ensure age is at least 1 month
      final finalAge = ageInMonths < 1 ? 1.0 : ageInMonths.toDouble();
      
      print('DEBUG: Birth date: $_selectedDate, Now: $now, Age in months: $finalAge');
      
      final animal = Animal(
        farmer: 0, // Will be set by backend from auth user
        species: _selectedSpecies!,
        age: finalAge,
        liveWeight: _weightValue,
        createdAt: DateTime.now(),
        slaughtered: false,
        animalId: _tagIdController.text,
        animalName: _tagIdController.text,
        breed: _breedController.text.isNotEmpty ? _breedController.text : null,
        abbatoirName: _abbatoirController.text.isNotEmpty ? _abbatoirController.text : 'Default Abattoir',
        healthStatus: _selectedHealthStatus,
      );

      await animalProvider.createAnimal(animal, photo: _selectedImage);

      if (mounted) {
        // Clear the local cache first to force a fresh fetch
        await animalProvider.clearAnimals();
        
        // Refresh the animal list to ensure UI is updated
        await animalProvider.fetchAnimals(slaughtered: null);
        
        print('📋 After registration: ${animalProvider.animals.length} animals loaded');
        
        _showSuccessSnackbar('Animal registered successfully!');
        
        // Small delay to ensure snackbar is visible
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate back to history or home
        if (mounted) {
          context.pop();
        }
        
        // Optionally navigate to livestock history
        // context.push('/livestock-history');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to register animal: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.farmerPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Register Animal',
        style: AppTypography.appBarTitle(color: Colors.white),
      ),
      actions: [
        if (!_isLoading)
          TextButton.icon(
            icon: const Icon(Icons.check, color: Colors.white),
            label: Text(
              'Save',
              style: AppTypography.labelLarge(color: Colors.white),
            ),
            onPressed: _registerAnimal,
          ),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPhotoSection(),
          const SizedBox(height: 24),
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          _buildPhysicalDetailsSection(),
          const SizedBox(height: 24),
          _buildHealthStatusSection(),
          const SizedBox(height: 24),
          _buildNotesSection(),
          const SizedBox(height: 32),
          _buildRegisterButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Animal Photo (Optional)',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.divider,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to add photo',
                            style: AppTypography.bodyMedium(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Change Photo'),
                  onPressed: _showImageSourceDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.farmerPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Remove'),
                  onPressed: () => setState(() => _selectedImage = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: 4),
          Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          
          // Tag ID
          CustomTextField(
            controller: _tagIdController,
            label: 'Tag ID',
            hint: 'Unique animal identifier',
            prefixIcon: const Icon(Icons.tag),
            readOnly: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tag ID is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Species Dropdown
          Text(
            'Species *',
            style: AppTypography.labelLarge(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSpecies,
            decoration: InputDecoration(
              hintText: 'Select species',
              prefixIcon: const Icon(Icons.pets),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.farmerPrimary, width: 2),
              ),
            ),
            items: _speciesOptions.map((species) {
              return DropdownMenuItem<String>(
                value: species['value'],
                child: Row(
                  children: [
                    Text(
                      species['icon'],
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(species['label']),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSpecies = value;
                _generateTagId();
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a species';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Breed
          CustomTextField(
            controller: _breedController,
            label: 'Breed',
            hint: 'e.g., Holstein, Yorkshire',
            prefixIcon: const Icon(Icons.category),
          ),
          const SizedBox(height: 16),
          
          // Date of Birth
          Text(
            'Date of Birth *',
            style: AppTypography.labelLarge(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: AppTypography.bodyLarge(),
                    ),
                  ),
                  Text(
                    _getAgeDisplay(),
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Abattoir Name
          CustomTextField(
            controller: _abbatoirController,
            label: 'Abattoir/Farm Name',
            hint: 'Enter farm or abattoir name',
            prefixIcon: const Icon(Icons.business),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Physical Details',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: 4),
          Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          
          // Weight Slider
          Text(
            'Live Weight (kg)',
            style: AppTypography.labelLarge(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _weightValue,
                  min: 0,
                  max: 1000,
                  divisions: 200,
                  activeColor: AppColors.farmerPrimary,
                  inactiveColor: AppColors.farmerPrimary.withOpacity(0.2),
                  onChanged: (value) {
                    setState(() {
                      _weightValue = value;
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.farmerPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_weightValue.toInt()} kg',
                  style: AppTypography.titleMedium(color: AppColors.farmerPrimary),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 kg', style: AppTypography.bodySmall(color: AppColors.textSecondary)),
              Text('1000 kg', style: AppTypography.bodySmall(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Gender
          Text(
            'Gender *',
            style: AppTypography.labelLarge(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  value: 'male',
                  label: 'Male',
                  icon: Icons.male,
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() => _selectedGender = value!);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRadioOption(
                  value: 'female',
                  label: 'Female',
                  icon: Icons.female,
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() => _selectedGender = value!);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Status',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: 4),
          Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          
          _buildHealthStatusOption(
            value: 'healthy',
            label: 'Healthy',
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          _buildHealthStatusOption(
            value: 'sick',
            label: 'Sick',
            icon: Icons.sick,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          _buildHealthStatusOption(
            value: 'under_treatment',
            label: 'Under Treatment',
            icon: Icons.medical_services,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Notes (Optional)',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: 4),
          Divider(color: AppColors.divider),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Add any additional information about the animal...',
              hintStyle: AppTypography.bodyMedium(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.backgroundGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.farmerPrimary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String label,
    required IconData icon,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.farmerPrimary.withOpacity(0.1)
              : AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.farmerPrimary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.farmerPrimary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge(
                color: isSelected ? AppColors.farmerPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatusOption({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = value == _selectedHealthStatus;
    
    return InkWell(
      onTap: () => setState(() => _selectedHealthStatus = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedHealthStatus,
              onChanged: (v) => setState(() => _selectedHealthStatus = v!),
              activeColor: color,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: isSelected ? color : AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.bodyLarge(
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _registerAnimal,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.farmerPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Register Animal',
                  style: AppTypography.button(color: Colors.white),
                ),
              ],
            ),
    );
  }

  String _getAgeDisplay() {
    final now = DateTime.now();
    final difference = now.difference(_selectedDate);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;
    
    if (years > 0) {
      return '$years yr${years > 1 ? 's' : ''} $months mo';
    }
    return '$months months';
  }
}
