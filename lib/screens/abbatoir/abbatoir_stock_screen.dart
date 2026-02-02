import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/animal_provider.dart';
import '../../providers/external_vendor_provider.dart';
import '../../models/animal.dart';
import '../../models/external_vendor.dart';
import '../../widgets/core/custom_app_bar.dart';
import '../../widgets/core/enhanced_back_button.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_typography.dart';

class AbbatoirStockScreen extends StatefulWidget {
  const AbbatoirStockScreen({super.key});

  @override
  State<AbbatoirStockScreen> createState() => _AbbatoirStockScreenState();
}

class _AbbatoirStockScreenState extends State<AbbatoirStockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _tagIdController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _breedController = TextEditingController();
  final _notesController = TextEditingController();

  // Selection state
  String _selectedSpecies = 'Cow';
  String _selectedGender = 'Male';
  SlaughterPartType _selectedPartType = SlaughterPartType.wholeCarcass;
  ExternalVendor? _selectedVendor;
  bool _isProcessing = false;

  final List<String> _speciesOptions = ['Cow', 'Goat', 'Sheep', 'Pig'];
  final List<String> _genderOptions = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    // Load vendors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExternalVendorProvider>().fetchVendors();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _tagIdController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _breedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitStock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      final animalProvider = context.read<AnimalProvider>();

      if (currentUser == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final tagId = _tagIdController.text.trim();
      final weight = double.tryParse(_weightController.text) ?? 0.0;
      final price = double.tryParse(_priceController.text);

      if (_tabController.index == 0) {
        // Register Live Animal
        final animal = Animal(
          abbatoir: currentUser.id,
          abbatoirName: currentUser.username,
          species: _selectedSpecies,
          animalId: tagId,
          animalName: _nameController.text.trim(),
          breed: _breedController.text.trim(),
          age: 0, // Default for opening stock
          liveWeight: weight,
          remainingWeight: weight,
          createdAt: now,
          slaughtered: false,
          gender: _selectedGender.toLowerCase(),
          healthStatus: 'Healthy',
          isExternal: true,
          externalVendorId: _selectedVendor?.id,
          externalVendorName: _selectedVendor?.name ?? 'Opening Stock',
          acquisitionPrice: price,
          acquisitionDate: now,
          originType: 'INITIAL_STOCK',
          notes: _notesController.text.trim(),
        );
        await animalProvider.createAnimal(animal);
      } else if (_tabController.index == 1) {
        // Register Slaughtered Animal
        final animal = Animal(
          abbatoir: currentUser.id ?? 0,
          abbatoirName: currentUser.username,
          species: _selectedSpecies,
          animalId: tagId,
          animalName: _nameController.text.trim(),
          age: 0,
          liveWeight: weight,
          remainingWeight: weight,
          createdAt: now,
          slaughtered: true,
          slaughteredAt: now,
          isExternal: true,
          externalVendorId: _selectedVendor?.id,
          externalVendorName: _selectedVendor?.name ?? 'Opening Stock',
          acquisitionPrice: price,
          acquisitionDate: now,
          originType: 'INITIAL_STOCK',
          notes: _notesController.text.trim(),
        );
        await animalProvider.createAnimal(animal);
      } else {
        // Register Slaughter Part
        // For slaughter parts as opening stock, we might need a dummy animal or just create the part record
        // Current model requires an animalId for a part.
        // We'll create a "Phantom Animal" to hold these initial parts if animalId is not provided.

        final phantomAnimal = Animal(
          abbatoir: currentUser.id ?? 0,
          abbatoirName: currentUser.username,
          species: _selectedSpecies,
          animalId: 'PART-HOLDER-${now.millisecondsSinceEpoch}',
          age: 0,
          liveWeight: weight,
          remainingWeight: 0,
          createdAt: now,
          slaughtered: true,
          slaughteredAt: now,
          gender: 'unknown',
          isExternal: true,
          receivedBy: currentUser.id,
          receivedAt: now,
          externalVendorName: 'Opening Stock (Parts)',
          originType: 'INITIAL_STOCK',
        );

        final createdAnimal = await animalProvider.createAnimal(phantomAnimal);
        if (createdAnimal?.id != null) {
          final part = SlaughterPart(
            animalId: createdAnimal!.id!,
            partType: _selectedPartType,
            weight: weight,
            weightUnit: 'kg',
            createdAt: now,
            description: _notesController.text.trim(),
            partId: tagId.isNotEmpty ? tagId : null,
          );
          await animalProvider.createSlaughterPart(part);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getCategoryName()} Added Successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding stock: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _tagIdController.clear();
    _weightController.clear();
    _priceController.clear();
    _breedController.clear();
    _notesController.clear();
    setState(() {
      _selectedVendor = null;
    });
  }

  String _getCategoryName() {
    switch (_tabController.index) {
      case 0:
        return 'Live Animal';
      case 1:
        return 'Slaughtered Animal';
      case 2:
        return 'Slaughter Part';
      default:
        return 'Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.abbatoirTheme,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Abbatoir Stock Entry',
          leading: const EnhancedBackButton(fallbackRoute: '/abbatoir-home'),
        ),
        body: Column(
          children: [
            _buildInfoBanner(),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.abbatoirPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.abbatoirPrimary,
              tabs: const [
                Tab(icon: Icon(Icons.pets), text: 'Live'),
                Tab(icon: Icon(Icons.checkroom), text: 'Slaughtered'),
                Tab(icon: Icon(Icons.restaurant), text: 'Parts'),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Vendor & Price'),
                      _buildVendorSelector(),
                      const SizedBox(height: AppTheme.space16),
                      _buildPriceField(),
                      const Divider(height: AppTheme.space32),

                      _buildSectionTitle('Item Details'),
                      if (_tabController.index != 2) _buildSpeciesSelector(),
                      if (_tabController.index == 2) _buildPartTypeSelector(),
                      const SizedBox(height: AppTheme.space16),
                      _buildTagIdField(),
                      const SizedBox(height: AppTheme.space16),
                      if (_tabController.index == 0) ...[
                        _buildGenderSelector(),
                        const SizedBox(height: AppTheme.space16),
                        _buildBreedField(),
                        const SizedBox(height: AppTheme.space16),
                      ],
                      _buildWeightField(),
                      const SizedBox(height: AppTheme.space16),
                      _buildNotesField(),
                      const SizedBox(height: AppTheme.space32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space12),
      color: AppColors.abbatoirPrimary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.abbatoirPrimary, size: 20),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(
              'Add animals or parts currently in your facility to start tracking.',
              style: AppTypography.bodySmall().copyWith(
                color: AppColors.abbatoirDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Text(
        title,
        style: AppTypography.titleMedium().copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVendorSelector() {
    return Consumer<ExternalVendorProvider>(
      builder: (context, provider, child) {
        return DropdownButtonFormField<ExternalVendor>(
          initialValue: _selectedVendor,
          decoration: const InputDecoration(
            labelText: 'Select Vendor',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
            hintText: 'Choose who brought the stock',
          ),
          items: [
            const DropdownMenuItem<ExternalVendor>(
              value: null,
              child: Text('Opening Stock / Internal'),
            ),
            ...provider.vendors.map(
              (v) => DropdownMenuItem(value: v, child: Text(v.name)),
            ),
          ],
          onChanged: (v) => setState(() => _selectedVendor = v),
        );
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Acquisition Price / Estimated Value',
        border: OutlineInputBorder(),
        prefixText: 'TZS ',
        prefixIcon: Icon(Icons.payments_outlined),
      ),
    );
  }

  Widget _buildSpeciesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Species', style: AppTypography.labelMedium()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _speciesOptions.map((s) {
            final isSelected = _selectedSpecies == s;
            return ChoiceChip(
              label: Text(s),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedSpecies = s),
              selectedColor: AppColors.abbatoirPrimary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.abbatoirPrimary
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPartTypeSelector() {
    return DropdownButtonFormField<SlaughterPartType>(
      initialValue: _selectedPartType,
      decoration: const InputDecoration(
        labelText: 'Part Type',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.restaurant),
      ),
      items: SlaughterPartType.values
          .map(
            (type) =>
                DropdownMenuItem(value: type, child: Text(type.displayName)),
          )
          .toList(),
      onChanged: (val) => setState(() => _selectedPartType = val!),
    );
  }

  Widget _buildTagIdField() {
    return TextFormField(
      controller: _tagIdController,
      decoration: InputDecoration(
        labelText: _tabController.index == 2
            ? 'Part ID / Batch'
            : 'Animal Tag ID',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.tag),
        hintText: 'e.g., COW-992',
      ),
      validator: (v) => v?.isEmpty == true ? 'Tag ID is required' : null,
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: AppTypography.labelMedium()),
        const SizedBox(height: 8),
        Row(
          children: _genderOptions.map((g) {
            final isSelected = _selectedGender == g;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilterChip(
                label: Text(g),
                selected: isSelected,
                onSelected: (val) => setState(() => _selectedGender = g),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBreedField() {
    return TextFormField(
      controller: _breedController,
      decoration: const InputDecoration(
        labelText: 'Breed (Optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.pets),
      ),
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Weight (kg)',
        border: OutlineInputBorder(),
        suffixText: 'kg',
        prefixIcon: Icon(Icons.monitor_weight_outlined),
      ),
      validator: (v) => v?.isEmpty == true ? 'Weight is required' : null,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Additional Notes',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _submitStock,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.abbatoirPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('Add to Stock', style: AppTypography.button()),
      ),
    );
  }
}
