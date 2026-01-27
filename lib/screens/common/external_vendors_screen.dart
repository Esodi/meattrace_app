import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/external_vendor_provider.dart';
import '../../models/external_vendor.dart';
import '../../widgets/core/custom_app_bar.dart';
import '../../widgets/core/enhanced_back_button.dart';

class ExternalVendorsScreen extends StatefulWidget {
  const ExternalVendorsScreen({super.key});

  @override
  State<ExternalVendorsScreen> createState() => _ExternalVendorsScreenState();
}

class _ExternalVendorsScreenState extends State<ExternalVendorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExternalVendorProvider>().fetchVendors();
    });
  }

  void _showAddVendorDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _contactController = TextEditingController();
    final _locationController = TextEditingController();
    ExternalVendorCategory _selectedCategory = ExternalVendorCategory.farmer;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add External Vendor'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Vendor Name',
                        hintText: 'e.g., John Doe Farm',
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Name is required' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ExternalVendorCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: ExternalVendorCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Info (Optional)',
                        hintText: 'Phone, Email, etc.',
                        prefixIcon: Icon(Icons.contact_phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (Optional)',
                        hintText: 'City, Region',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newVendor = ExternalVendor(
                      name: _nameController.text.trim(),
                      contactInfo: _contactController.text.trim().isEmpty
                          ? null
                          : _contactController.text.trim(),
                      location: _locationController.text.trim().isEmpty
                          ? null
                          : _locationController.text.trim(),
                      category: _selectedCategory,
                    );

                    final provider = context.read<ExternalVendorProvider>();
                    final created = await provider.addVendor(newVendor);

                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                      if (created != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Vendor "${created.name}" added'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Add Vendor'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'External Vendors',
        leading: EnhancedBackButton(fallbackRoute: '/settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddVendorDialog(context),
            tooltip: 'Add Vendor',
          ),
        ],
      ),
      body: Consumer<ExternalVendorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.vendors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No external vendors yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add vendors to track purchases from outside sources',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddVendorDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Vendor'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.vendors.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final vendor = provider.vendors[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    _getIconForCategory(vendor.category),
                    color: Colors.blue.shade800,
                  ),
                ),
                title: Text(vendor.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.category.displayName),
                    if (vendor.location != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vendor.location!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: View vendor details or edit
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(ExternalVendorCategory category) {
    switch (category) {
      case ExternalVendorCategory.farmer:
        return Icons.agriculture;
      case ExternalVendorCategory.abbatoir:
        return Icons.house_siding; // Approximate for abbatoir
      case ExternalVendorCategory.processor:
        return Icons.factory;
      case ExternalVendorCategory.distributor:
        return Icons.local_shipping;
      case ExternalVendorCategory.other:
        return Icons.business;
    }
  }
}
