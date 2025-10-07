import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building ThemeToggle');
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider!.isDarkMode;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceWhite.withOpacity(0.1) : AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppTheme.dividerGray.withOpacity(0.3) : AppTheme.dividerGray,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Light mode button
              _buildToggleButton(
                context: context,
                icon: Icons.wb_sunny,
                label: 'Light',
                isSelected: !isDark,
                onTap: () => themeProvider.setLightMode(),
                tooltip: 'Switch to light theme',
              ),

              // Dark mode button
              _buildToggleButton(
                context: context,
                icon: Icons.nightlight_round,
                label: 'Dark',
                isSelected: isDark,
                onTap: () => themeProvider.setDarkMode(),
                tooltip: 'Switch to dark theme',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                size: 18,
                semanticLabel: '$label mode',
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccessibilityToggle extends StatefulWidget {
  const AccessibilityToggle({super.key});

  @override
  State<AccessibilityToggle> createState() => _AccessibilityToggleState();
}

class _AccessibilityToggleState extends State<AccessibilityToggle> {
  bool _highContrast = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'high_contrast':
            setState(() => _highContrast = !_highContrast);
            // Apply high contrast theme
            break;
          case 'large_text':
            // Increase text size
            break;
          case 'reduce_motion':
            // Disable animations
            break;
        }
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'high_contrast',
          checked: _highContrast,
          child: const Text('High Contrast'),
        ),
        const PopupMenuItem(
          value: 'large_text',
          child: Text('Large Text'),
        ),
        const PopupMenuItem(
          value: 'reduce_motion',
          child: Text('Reduce Motion'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Icon(
          Icons.accessibility,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}







