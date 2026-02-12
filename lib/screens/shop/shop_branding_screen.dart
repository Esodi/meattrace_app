import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/shop_settings_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

class ShopBrandingScreen extends StatefulWidget {
  const ShopBrandingScreen({super.key});

  @override
  State<ShopBrandingScreen> createState() => _ShopBrandingScreenState();
}

class _ShopBrandingScreenState extends State<ShopBrandingScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _logoUrlController;
  late TextEditingController _headerTextController;
  late TextEditingController _footerTextController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _websiteController;
  late TextEditingController _taxLabelController;
  late TextEditingController _taxRateController;
  late TextEditingController _invoicePrefixController;
  late TextEditingController _taxIdController;

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _logoUrlController = TextEditingController();
    _headerTextController = TextEditingController();
    _footerTextController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _websiteController = TextEditingController();
    _taxLabelController = TextEditingController();
    _taxRateController = TextEditingController();
    _invoicePrefixController = TextEditingController();
    _taxIdController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final settingsProvider = Provider.of<ShopSettingsProvider>(
            context,
            listen: false,
          );
          if (settingsProvider.settings == null) {
            settingsProvider.loadSettings().then((_) {
              if (mounted) _populateFields();
            });
          } else {
            _populateFields();
          }
        }
      });
      _isInit = false;
    }
  }

  void _populateFields() {
    final settings = Provider.of<ShopSettingsProvider>(
      context,
      listen: false,
    ).settings;
    if (settings != null) {
      _companyNameController.text = settings.companyName ?? '';
      _logoUrlController.text = settings.companyLogoUrl ?? settings.logo ?? '';
      _headerTextController.text = settings.headerText ?? '';
      _footerTextController.text = settings.footerText ?? '';
      _emailController.text = settings.businessEmail ?? '';
      _phoneController.text = settings.businessPhone ?? '';
      _addressController.text = settings.businessAddress ?? '';
      _websiteController.text = settings.website ?? '';
      _taxLabelController.text = settings.taxLabel;
      _taxRateController.text = settings.taxRate.toString();
      _invoicePrefixController.text = settings.invoicePrefix;
      _taxIdController.text = settings.taxId ?? '';
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _logoUrlController.dispose();
    _headerTextController.dispose();
    _footerTextController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _taxLabelController.dispose();
    _taxRateController.dispose();
    _invoicePrefixController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<ShopSettingsProvider>(context, listen: false);

    // If settings haven't loaded yet, try loading them first
    if (provider.settings == null) {
      await provider.loadSettings();
    }

    final settings = provider.settings;
    if (settings == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings not loaded yet. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saving settings...')));

      // Send all fields in a single PATCH request
      final data = <String, dynamic>{
        'company_name': _companyNameController.text.trim(),
        'business_email': _emailController.text.trim(),
        'business_phone': _phoneController.text.trim(),
        'business_address': _addressController.text.trim(),
        'website': _websiteController.text.trim(),
        'company_logo_url': _logoUrlController.text.trim(),
        'company_header': _headerTextController.text.trim(),
        'company_footer': _footerTextController.text.trim(),
        'tax_rate': double.tryParse(_taxRateController.text) ?? 0.0,
        'invoice_prefix': _invoicePrefixController.text.trim().toUpperCase(),
        'tax_id': _taxIdController.text.trim(),
      };

      final taxLabel = _taxLabelController.text.trim();
      if (taxLabel.isNotEmpty) data['tax_label'] = taxLabel;

      await provider.saveAllSettings(settings.id!, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<ShopSettingsProvider>(context);
    final isLoading = settingsProvider.isLoading;
    final theme = Theme.of(context);
    final primaryColor = AppColors.shopPrimary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppColors.shopPrimary,
        foregroundColor: Colors.white,
        title: Text(
          'Business Profile & Branding',
          style: AppTypography.headlineSmall().copyWith(color: Colors.white),
        ),
        actions: [
          if (!isLoading)
            IconButton(
              onPressed: _saveSettings,
              icon: const Icon(Icons.check, color: Colors.white),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('General Information', primaryColor),
                    _buildTextField(
                      controller: _companyNameController,
                      label: 'Company Name',
                      hint: 'e.g. Tamu Meat Shop',
                      icon: Icons.business,
                      primaryColor: primaryColor,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    _buildTextField(
                      controller: _taxIdController,
                      label: 'Shop TIN',
                      hint: 'e.g. 141-821-571',
                      icon: Icons.tag,
                      primaryColor: primaryColor,
                    ),
                    _buildTextField(
                      controller: _logoUrlController,
                      label: 'Logo Image URL',
                      hint: 'https://example.com/logo.png',
                      icon: Icons.image_outlined,
                      primaryColor: primaryColor,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _taxLabelController,
                            label: 'Tax Label',
                            hint: 'VAT/GST',
                            icon: Icons.label_outline,
                            primaryColor: primaryColor,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: _buildTextField(
                            controller: _taxRateController,
                            label: 'Tax Rate (%)',
                            hint: '18.0',
                            icon: Icons.percent,
                            primaryColor: primaryColor,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      controller: _invoicePrefixController,
                      label: 'Invoice Prefix',
                      hint: 'INV',
                      icon: Icons.numbers,
                      primaryColor: primaryColor,
                    ),

                    const SizedBox(height: AppTheme.space24),
                    _buildSectionHeader('Contact Details', primaryColor),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Business Email',
                      hint: 'contact@shop.com',
                      icon: Icons.email_outlined,
                      primaryColor: primaryColor,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Business Phone',
                      hint: '+255...',
                      icon: Icons.phone_outlined,
                      primaryColor: primaryColor,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Physical Address',
                      hint: 'Plot 123, Mwanza',
                      icon: Icons.location_on_outlined,
                      primaryColor: primaryColor,
                      maxLines: 2,
                    ),
                    _buildTextField(
                      controller: _websiteController,
                      label: 'Website',
                      hint: 'www.tamumeat.com',
                      icon: Icons.language,
                      primaryColor: primaryColor,
                    ),

                    const SizedBox(height: AppTheme.space24),
                    _buildSectionHeader('Invoicing Layout', primaryColor),
                    _buildTextField(
                      controller: _headerTextController,
                      label: 'Header Text',
                      hint: 'Appears at the top of the PDF',
                      icon: Icons.vertical_align_top,
                      primaryColor: primaryColor,
                      maxLines: 3,
                    ),
                    _buildTextField(
                      controller: _footerTextController,
                      label: 'Footer Text',
                      hint: 'Terms, thank you message, etc.',
                      icon: Icons.vertical_align_bottom,
                      primaryColor: primaryColor,
                      maxLines: 3,
                    ),

                    const SizedBox(height: AppTheme.space32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                        ),
                        child: const Text('Save Business Profile'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: Text(
        title,
        style: AppTypography.titleLarge().copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color primaryColor,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }
}
