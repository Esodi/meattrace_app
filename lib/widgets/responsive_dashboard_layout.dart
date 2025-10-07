import 'package:flutter/material.dart';
import 'dashboard_sidebar.dart';
import '../utils/responsive.dart';

class ResponsiveDashboardLayout extends StatefulWidget {
  final Widget content;
  final String currentRoute;

  const ResponsiveDashboardLayout({
    super.key,
    required this.content,
    required this.currentRoute,
  });

  @override
  State<ResponsiveDashboardLayout> createState() => _ResponsiveDashboardLayoutState();
}

class _ResponsiveDashboardLayoutState extends State<ResponsiveDashboardLayout> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    if (isDesktop || isTablet) {
      // Desktop/Tablet layout with sidebar
      return Row(
        children: [
          DashboardSidebar(
            isCollapsed: _sidebarCollapsed,
            onToggle: (collapsed) => setState(() => _sidebarCollapsed = collapsed),
            currentRoute: widget.currentRoute,
          ),
          Expanded(
            child: widget.content,
          ),
        ],
      );
    } else {
      // Mobile layout - content only, sidebar accessible via drawer
      return Scaffold(
        drawer: Drawer(
          child: DashboardSidebar(
            isCollapsed: false, // Always expanded in drawer
            onToggle: (_) {}, // No toggle in drawer
            currentRoute: widget.currentRoute,
          ),
        ),
        body: widget.content,
      );
    }
  }
}

class DashboardGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  const DashboardGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return crossAxisCount + 1; // More columns on desktop
    } else if (Responsive.isTablet(context)) {
      return crossAxisCount; // Standard for tablet
    } else {
      return crossAxisCount - 1; // Fewer columns on mobile
    }
  }
}

class DashboardSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  const DashboardSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: Responsive.getPadding(context),
            vertical: 8.0,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        if (showDivider) const Divider(),
        ...children,
      ],
    );
  }
}







