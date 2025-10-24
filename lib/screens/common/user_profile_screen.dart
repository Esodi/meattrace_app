import 'package:flutter/material.dart';
import '../../services/dio_client.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _organizationController = TextEditingController();
  
  String _userRole = '';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final userData = await apiService.fetchProfile();

      setState(() {
        _userId = userData['id'];
        _usernameController.text = userData['username'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _firstNameController.text = userData['first_name'] ?? '';
        _lastNameController.text = userData['last_name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _organizationController.text = userData['organization'] ?? '';
        _userRole = userData['role'] ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      await apiService.updateProfile({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'organization': _organizationController.text.trim(),
      });

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _updateProfile,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getRoleColor(),
                          _getRoleColor().withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Text(
                            _getInitials(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _getRoleColor(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_firstNameController.text} ${_lastNameController.text}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRoleLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Form
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildProfileField(
                            controller: _usernameController,
                            label: 'Username',
                            icon: Icons.person,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildProfileField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            enabled: _isEditing,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildProfileField(
                            controller: _firstNameController,
                            label: 'First Name',
                            icon: Icons.badge,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildProfileField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            icon: Icons.badge_outlined,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildProfileField(
                            controller: _phoneController,
                            label: 'Phone',
                            icon: Icons.phone,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 24),
                          
                          const Text(
                            'Organization',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildProfileField(
                            controller: _organizationController,
                            label: 'Organization Name',
                            icon: Icons.business,
                            enabled: _isEditing,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Statistics (read-only)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Account Statistics',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(height: 24),
                                _buildStatRow('User ID', '#$_userId'),
                                _buildStatRow('Role', _getRoleLabel()),
                                _buildStatRow('Username', _usernameController.text),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final shouldLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Logout'),
                                    content: const Text('Are you sure you want to logout?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (shouldLogout == true && mounted) {
                                  await AuthService().logout();
                                  if (mounted) {
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/login',
                                      (route) => false,
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  String _getRoleLabel() {
    switch (_userRole.toLowerCase()) {
      case 'farmer':
        return 'Farmer/Abattoir';
      case 'processor':
        return 'Processing Unit';
      case 'shop':
        return 'Shop/Retail';
      default:
        return _userRole;
    }
  }

  Color _getRoleColor() {
    switch (_userRole.toLowerCase()) {
      case 'farmer':
        return AppColors.farmerPrimary;
      case 'processor':
        return AppColors.processorPrimary;
      case 'shop':
        return AppColors.shopPrimary;
      default:
        return Colors.grey;
    }
  }
}
