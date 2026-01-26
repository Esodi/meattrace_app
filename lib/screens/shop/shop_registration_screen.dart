import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../providers/shop_management_provider.dart';
import '../../models/shop.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_text_field.dart';

class ShopRegistrationScreen extends StatefulWidget {
  const ShopRegistrationScreen({super.key});

  @override
  State<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends State<ShopRegistrationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();

  // Form controllers for Create New Shop
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessLicenseController = TextEditingController();
  final _taxIdController = TextEditingController();

  // Join existing shop
  Shop? _selectedShop;
  String _selectedRole = 'salesperson';
  final _messageController = TextEditingController();

  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load available shops when switching to join tab
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        context.read<ShopManagementProvider>().loadAvailableShops();
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
    _businessLicenseController.dispose();
    _taxIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final shop = Shop(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      contactEmail: _emailController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      businessLicense: _businessLicenseController.text.trim(),
      taxId: _taxIdController.text.trim(),
    );

    final provider = context.read<ShopManagementProvider>();
    final success = await provider.createShop(shop);

    setState(() => _isCreating = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shop created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/shop-home');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to create shop'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitJoinRequest() async {
    if (_selectedShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a shop'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    final provider = context.read<ShopManagementProvider>();
    final success = await provider.requestJoinShop(
      shopId: _selectedShop!.id!,
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
        title: Text('Shop Registration', style: AppTypography.headlineSmall()),
        backgroundColor: AppColors.shopPrimary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Create New Shop'),
            Tab(text: 'Join Existing Shop'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCreateShopTab(), _buildJoinShopTab()],
      ),
    );
  }

  Widget _buildCreateShopTab() {
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
                color: AppColors.shopPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(Icons.store, size: 40, color: AppColors.shopPrimary),
                  SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Your Shop',
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

            // Shop Name
            CustomTextField(
              controller: _nameController,
              label: 'Shop Name *',
              hint: 'e.g., Fresh Meat Market',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter shop name';
                }
                return null;
              },
            ),

            SizedBox(height: AppTheme.space16),

            // Description
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Brief description of your shop',
              maxLines: 3,
            ),

            SizedBox(height: AppTheme.space16),

            // Location
            CustomTextField(
              controller: _locationController,
              label: 'Location *',
              hint: 'Street Address, City, State',
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
              hint: 'contact@shop.com',
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
              label: 'Contact Phone *',
              hint: '+1234567890',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),

            SizedBox(height: AppTheme.space24),

            // Business Information Section
            Text('Business Information', style: AppTypography.headlineSmall()),
            SizedBox(height: AppTheme.space16),

            // Business License
            CustomTextField(
              controller: _businessLicenseController,
              label: 'Business License',
              hint: 'License number',
            ),

            SizedBox(height: AppTheme.space16),

            // Tax ID
            CustomTextField(
              controller: _taxIdController,
              label: 'Tax ID',
              hint: 'Tax identification number',
            ),

            SizedBox(height: AppTheme.space32),

            // Create Button
            _isCreating
                ? Center(child: CircularProgressIndicator())
                : CustomButton(
                    label: 'Create Shop',
                    onPressed: _createShop,
                    customColor: AppColors.shopPrimary,
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
                      'After creating your shop, you can invite staff members and assign roles (Manager, Salesperson, Cashier, Inventory Clerk).',
                      style: AppTypography.caption().copyWith(
                        color: AppColors.info,
                      ),
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

  Widget _buildJoinShopTab() {
    return Consumer<ShopManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.availableShops.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: EdgeInsets.all(AppTheme.space16),
              child: CustomTextField(
                controller: _searchController,
                label: 'Search Shops',
                hint: 'Search by name or location',
                prefixIcon: Icon(Icons.search),
                onChanged: (value) {
                  if (value.length >= 3 || value.isEmpty) {
                    provider.loadAvailableShops(search: value);
                  }
                },
              ),
            ),

            // Shops List
            Expanded(
              child: provider.availableShops.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                      ),
                      itemCount: provider.availableShops.length,
                      itemBuilder: (context, index) {
                        final shop = provider.availableShops[index];
                        return _buildShopCard(shop);
                      },
                    ),
            ),

            // Selected Shop and Request Form
            if (_selectedShop != null) _buildRequestForm(),
          ],
        );
      },
    );
  }

  Widget _buildShopCard(Shop shop) {
    final isSelected = _selectedShop?.id == shop.id;

    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.space12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: isSelected ? AppColors.shopPrimary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() {
          _selectedShop = isSelected ? null : shop;
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
                  color: AppColors.shopPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.store,
                  color: AppColors.shopPrimary,
                  size: 28,
                ),
              ),

              SizedBox(width: AppTheme.space16),

              // Shop Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: AppTypography.bodyLarge().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (shop.location != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.location!,
                              style: AppTypography.caption(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (shop.description != null) ...[
                      SizedBox(height: 4),
                      Text(
                        shop.description!,
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
                  color: AppColors.shopPrimary,
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
        color: AppColors.shopPrimary.withOpacity(0.05),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Submit Join Request', style: AppTypography.headlineSmall()),
          SizedBox(height: AppTheme.space16),

          // Role Selection
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Preferred Role',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'salesperson',
                child: Text('Salesperson'),
              ),
              DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
              DropdownMenuItem(
                value: 'inventory_clerk',
                child: Text('Inventory Clerk'),
              ),
              DropdownMenuItem(value: 'manager', child: Text('Manager')),
            ],
            onChanged: (value) => setState(() => _selectedRole = value!),
          ),

          SizedBox(height: AppTheme.space16),

          // Message
          CustomTextField(
            controller: _messageController,
            label: 'Message (Optional)',
            hint: 'Explain why you want to join this shop',
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
                        onPressed: () => setState(() => _selectedShop = null),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: AppTheme.space16),
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        label: 'Send Request',
                        onPressed: _submitJoinRequest,
                        customColor: AppColors.shopPrimary,
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
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
          SizedBox(height: AppTheme.space16),
          Text('No shops found', style: AppTypography.headlineSmall()),
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
