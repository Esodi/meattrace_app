import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoSync = true;
  String _selectedTheme = 'system';
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _autoSync = prefs.getBool('auto_sync') ?? true;
      _selectedTheme = prefs.getString('theme') ?? 'system';
      _selectedLanguage = prefs.getString('language') ?? 'en';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Notifications',
            icon: Icons.notifications,
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive push notifications'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _saveSetting('notifications_enabled', value);
                },
              ),
              SwitchListTile(
                title: const Text('Sound'),
                subtitle: const Text('Play notification sounds'),
                value: _soundEnabled,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _soundEnabled = value);
                        _saveSetting('sound_enabled', value);
                      }
                    : null,
              ),
              SwitchListTile(
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate for notifications'),
                value: _vibrationEnabled,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _vibrationEnabled = value);
                        _saveSetting('vibration_enabled', value);
                      }
                    : null,
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'Appearance',
            icon: Icons.palette,
            children: [
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(_getThemeLabel(_selectedTheme)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showThemeDialog(),
              ),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(_getLanguageLabel(_selectedLanguage)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'Data & Storage',
            icon: Icons.storage,
            children: [
              SwitchListTile(
                title: const Text('Auto Sync'),
                subtitle: const Text('Automatically sync data when online'),
                value: _autoSync,
                onChanged: (value) {
                  setState(() => _autoSync = value);
                  _saveSetting('auto_sync', value);
                },
              ),
              ListTile(
                title: const Text('Clear Cache'),
                subtitle: const Text('Free up storage space'),
                trailing: const Icon(Icons.cleaning_services),
                onTap: () => _showClearCacheDialog(),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'Account',
            icon: Icons.account_circle,
            children: [
              ListTile(
                title: const Text('Profile'),
                subtitle: const Text('View and edit your profile'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                title: const Text('Change Password'),
                subtitle: const Text('Update your account password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showChangePasswordDialog(),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'About',
            icon: Icons.info,
            children: [
              ListTile(
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to privacy policy
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy coming soon')),
                  );
                },
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to terms of service
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terms of Service coming soon')),
                  );
                },
              ),
              ListTile(
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to help & support
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & Support coming soon')),
                  );
                },
              ),
            ],
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
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
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.processorPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.processorPrimary,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System Default';
      default:
        return theme;
    }
  }

  String _getLanguageLabel(String lang) {
    switch (lang) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      default:
        return lang;
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                _saveSetting('theme', value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                _saveSetting('theme', value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'system',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                _saveSetting('theme', value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                _saveSetting('language', value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Spanish'),
              value: 'es',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                _saveSetting('language', value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('French'),
              value: 'fr',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                _saveSetting('language', value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the cache? This will free up storage space but may slow down the app temporarily.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
