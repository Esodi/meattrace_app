import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';

class QuickActionFAB extends StatelessWidget {
  const QuickActionFAB({super.key});

  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pause Processing'),
          content: const Text('Are you sure you want to pause the current processing batch?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Processing paused')),
                );
              },
              child: const Text('Pause'),
            ),
          ],
        );
      },
    );
  }

  void _showStopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stop Processing'),
          content: const Text('Are you sure you want to stop the current processing batch? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Processing stopped')),
                );
              },
              child: const Text('Stop'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = Responsive.getButtonHeight(context);
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: AppTheme.primaryRed,
      foregroundColor: Colors.white,
      activeBackgroundColor: AppTheme.primaryRed.withOpacity(0.8),
      activeForegroundColor: Colors.white,
      buttonSize: Size.square(buttonSize),
      visible: true,
      closeManually: false,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      onOpen: () => debugPrint('OPENING DIAL'),
      onClose: () => debugPrint('DIAL CLOSED'),
      elevation: 8.0,
      shape: const CircleBorder(),
      children: [
        SpeedDialChild(
          child: const Icon(Icons.play_arrow, color: Colors.white),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          label: 'Start Processing',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.primaryGreen,
          onTap: () => context.go('/create-product'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.pause, color: Colors.white),
          backgroundColor: AppTheme.accentOrange,
          foregroundColor: Colors.white,
          label: 'Pause Processing',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.accentOrange,
          onTap: () => _showPauseDialog(context),
        ),
        SpeedDialChild(
          child: const Icon(Icons.stop, color: Colors.white),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          label: 'Stop Processing',
          labelStyle: const TextStyle(fontSize: 14.0, color: Colors.white),
          labelBackgroundColor: AppTheme.primaryRed,
          onTap: () => _showStopDialog(context),
        ),
      ],
    );
  }
}

class ExpandableFAB extends StatefulWidget {
  final List<FABAction> actions;

  const ExpandableFAB({
    super.key,
    required this.actions,
  });

  @override
  State<ExpandableFAB> createState() => _ExpandableFABState();
}

class FABAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? tooltip;

  const FABAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });
}

class _ExpandableFABState extends State<ExpandableFAB> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action buttons
        ...widget.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final offset = _isOpen ? (index + 1) * 70.0 * _animation.value : 0.0;
              return Transform.translate(
                offset: Offset(0, -offset),
                child: AnimatedOpacity(
                  opacity: _isOpen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton.extended(
                    heroTag: null,
                    onPressed: () {
                      action.onPressed();
                      _toggle();
                    },
                    backgroundColor: action.color,
                    foregroundColor: Colors.white,
                    icon: Icon(action.icon),
                    label: Text(action.label),
                    tooltip: action.tooltip,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              );
            },
          );
        }),

        const SizedBox(height: 16),

        // Main FAB
        FloatingActionButton(
          heroTag: null,
          onPressed: _toggle,
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          elevation: 8,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animation,
          ),
        ),
      ],
    );
  }
}

class ContextualFAB extends StatelessWidget {
  final String context;
  final VoidCallback? onPressed;

  const ContextualFAB({
    super.key,
    required this.context,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String tooltip;
    Color backgroundColor;

    switch (this.context.toLowerCase()) {
      case 'register':
        icon = Icons.add;
        tooltip = 'Register New Livestock';
        backgroundColor = AppTheme.primaryGreen;
        break;
      case 'scan':
        icon = Icons.qr_code_scanner;
        tooltip = 'Scan QR Code';
        backgroundColor = AppTheme.secondaryBlue;
        break;
      case 'transfer':
        icon = Icons.send;
        tooltip = 'Transfer Animals';
        backgroundColor = AppTheme.accentOrange;
        break;
      case 'report':
        icon = Icons.analytics;
        tooltip = 'Generate Report';
        backgroundColor = AppTheme.secondaryBurgundy;
        break;
      default:
        icon = Icons.add;
        tooltip = 'Quick Action';
        backgroundColor = AppTheme.primaryRed;
    }

    return FloatingActionButton(
      heroTag: null,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      elevation: 8,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}

class ProcessorFAB extends StatelessWidget {
  const ProcessorFAB({super.key});

  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Action buttons
              ..._buildActionButtons(context),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final actions = [
      {
        'icon': Icons.send,
        'label': 'Transfer Products',
        'route': '/select-products-transfer',
        'color': AppTheme.secondaryBurgundy,
        'description': 'Send processed products to shops',
      },
      {
        'icon': Icons.play_arrow,
        'label': 'Initiate Processing Batch',
        'route': '/create-product',
        'color': AppTheme.primaryGreen,
        'description': 'Start a new meat processing batch',
      },
      {
        'icon': Icons.inventory,
        'label': 'View Inventory',
        'route': '/inventory-management',
        'color': AppTheme.secondaryBlue,
        'description': 'Check current stock levels',
      },
      {
        'icon': Icons.shortcut,
        'label': 'Access Shortcuts',
        'route': null, // Will show another modal or navigate to settings
        'color': AppTheme.accentOrange,
        'description': 'Quick access to common tasks',
      },
    ];

    return actions.map((action) {
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: action['color'] as Color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            action['icon'] as IconData,
            color: Colors.white,
          ),
        ),
        title: Text(action['label'] as String),
        subtitle: Text(action['description'] as String),
        onTap: () {
          Navigator.of(context).pop(); // Close the bottom sheet
          final route = action['route'] as String?;
          if (route != null) {
            context.go(route);
          } else if (action['label'] == 'Access Shortcuts') {
            _showShortcutsDialog(context);
          }
        },
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      );
    }).toList();
  }

  void _showShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Common Tasks Shortcuts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Quick Scan QR'),
                subtitle: const Text('Scan QR codes for verification'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/qr-scanner?source=processor');
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text('Receive Animals'),
                subtitle: const Text('Receive incoming livestock'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/receive-animals');
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_business),
                title: const Text('Create Product'),
                subtitle: const Text('Add new processed products'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/create-product');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Quick actions menu',
      hint: 'Tap to show quick action options for processor tasks',
      button: true,
      child: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showQuickActionsSheet(context),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 8,
        tooltip: 'Quick Actions',
        child: const Icon(Icons.add),
      ),
    );
  }
}







