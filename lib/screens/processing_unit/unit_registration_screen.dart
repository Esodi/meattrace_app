import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../providers/processing_unit_management_provider.dart';
import '../../models/processing_unit.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_text_field.dart';

class ProcessingUnitRegistrationScreen extends StatefulWidget {
  const ProcessingUnitRegistrationScreen({super.key});

  @override
  State<ProcessingUnitRegistrationScreen> createState() =>
      _ProcessingUnitRegistrationScreenState();
}

class _ProcessingUnitRegistrationScreenState
    extends State<ProcessingUnitRegistrationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();

  // Form controllers for Create New Unit
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();

  // Join existing unit
  ProcessingUnit? _selectedUnit;
  String _selectedRole = 'worker';
  final _messageController = TextEditingController();

  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load available units when switching to join tab
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        context.read<ProcessingUnitManagementProvider>().loadAvailableUnits();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createUnit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final unit = ProcessingUnit(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      contactEmail: _emailController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
    );

    final provider = context.read<ProcessingUnitManagementProvider>();
    final success = await provider.createProcessingUnit(unit);

    setState(() => _isCreating = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing unit created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/processor-home');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to create processing unit'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitJoinRequest() async {
    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a processing unit'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    final provider = context.read<ProcessingUnitManagementProvider>();
    final success = await provider.requestJoinUnit(
      unitId: _selectedUnit!.id!,
      requestedRole: _selectedRole,
      message: _messageController.text.trim(),
    );

    setState(() => _isCreating = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Join request sent! Waiting for approval.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to send join request'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Processing Unit Registration',
          style: AppTypography.headlineSmall(),
        ),
        backgroundColor: AppColors.processorPrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Create New Unit'),
            Tab(text: 'Join Existing Unit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateUnitTab(),
          _buildJoinUnitTab(),
        ],
      ),
    );
  }

  Widget _buildCreateUnitTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.space24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.processorPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.factory,
                    size: 40,
                    color: AppColors.processorPrimary,
                  ),
                  SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Your Processing Unit',
                          style: AppTypography.headlineSmall(),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You will be assigned as the owner with full access',
                          style: AppTypography.caption(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppTheme.space32),

            // Unit Name
            CustomTextField(
              controller: _nameController,
              label: 'Unit Name *',
              hint: 'e.g., MeatCo Processing',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter unit name';
                }
                return null;
              },
            ),

            SizedBox(height: AppTheme.space16),

            // Description
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Brief description of your processing unit',
              maxLines: 3,
            ),

            SizedBox(height: AppTheme.space16),

            // Location
            CustomTextField(
              controller: _locationController,
              label: 'Location *',
              hint: 'City, State/Province',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),

            SizedBox(height: AppTheme.space16),

            // Contact Email
            CustomTextField(
              controller: _emailController,
              label: 'Contact Email *',
              hint: 'contact@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            SizedBox(height: AppTheme.space16),

            // Contact Phone
            CustomTextField(
              controller: _phoneController,
              label: 'Contact Phone',
              hint: '+1234567890',
              keyboardType: TextInputType.phone,
            ),

            SizedBox(height: AppTheme.space16),

            // License Number
            CustomTextField(
              controller: _licenseController,
              label: 'License Number',
              hint: 'Business license or registration number',
            ),

            SizedBox(height: AppTheme.space32),

            // Create Button
            _isCreating
                ? Center(child: CircularProgressIndicator())
                : CustomButton(
                    label: 'Create Processing Unit',
                    onPressed: _createUnit,
                    customColor: AppColors.processorPrimary,
                  ),

            SizedBox(height: AppTheme.space16),

            // Info text
            Container(
              padding: EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      'After creating your unit, you can invite team members and assign roles.',
                      style: AppTypography.caption().copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinUnitTab() {
    return Consumer<ProcessingUnitManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.availableUnits.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.all(AppTheme.space16),
              child: CustomTextField(
                controller: _searchController,
                label: 'Search Processing Units',
                hint: 'Search by name or location',
                prefixIcon: Icon(Icons.search),
                onChanged: (value) {
                  if (value.length >= 3 || value.isEmpty) {
                    provider.loadAvailableUnits(search: value);
                  }
                },
              ),
            ),

            // Units List
            Expanded(
              child: provider.availableUnits.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: AppTheme.space16),
                      itemCount: provider.availableUnits.length,
                      itemBuilder: (context, index) {
                        final unit = provider.availableUnits[index];
                        return _buildUnitCard(unit);
                      },
                    ),
            ),

            // Selected Unit and Request Form
            if (_selectedUnit != null) _buildRequestForm(),
          ],
        );
      },
    );
  }

  Widget _buildUnitCard(ProcessingUnit unit) {
    final isSelected = _selectedUnit?.id == unit.id;

    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.space12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: isSelected ? AppColors.processorPrimary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() {
          _selectedUnit = isSelected ? null : unit;
        }),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.processorPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.factory,
                  color: AppColors.processorPrimary,
                  size: 28,
                ),
              ),

              SizedBox(width: AppTheme.space16),

              // Unit Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name,
                      style: AppTypography.bodyLarge().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unit.location != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            unit.location!,
                            style: AppTypography.caption(),
                          ),
                        ],
                      ),
                    ],
                    if (unit.description != null) ...[
                      SizedBox(height: 4),
                      Text(
                        unit.description!,
                        style: AppTypography.caption(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Selection Indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.processorPrimary,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Container(
      padding: EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppColors.processorPrimary.withOpacity(0.05),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Submit Join Request',
            style: AppTypography.headlineSmall(),
          ),
          SizedBox(height: AppTheme.space16),

          // Role Selection
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Preferred Role',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            items: [
              DropdownMenuItem(value: 'worker', child: Text('Worker')),
              DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
              DropdownMenuItem(value: 'quality_control', child: Text('Quality Control')),
              DropdownMenuItem(value: 'manager', child: Text('Manager')),
            ],
            onChanged: (value) => setState(() => _selectedRole = value!),
          ),

          SizedBox(height: AppTheme.space16),

          // Message
          CustomTextField(
            controller: _messageController,
            label: 'Message (Optional)',
            hint: 'Explain why you want to join this unit',
            maxLines: 3,
          ),

          SizedBox(height: AppTheme.space16),

          // Submit Button
          _isCreating
              ? Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selectedUnit = null),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: AppTheme.space16),
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        label: 'Send Request',
                        onPressed: _submitJoinRequest,
                        customColor: AppColors.processorPrimary,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: AppTheme.space16),
          Text(
            'No processing units found',
            style: AppTypography.headlineSmall(),
          ),
          SizedBox(height: AppTheme.space8),
          Text(
            'Try adjusting your search',
            style: AppTypography.bodyMedium().copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
