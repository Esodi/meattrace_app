import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double getPadding(BuildContext context) =>
      isMobile(context) ? 16.0 : isTablet(context) ? 24.0 : 32.0;

  static double getFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) return baseSize;
    if (isTablet(context)) return baseSize * 1.2;
    return baseSize * 1.4;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  static double getCardElevation(BuildContext context) =>
      isMobile(context) ? 4.0 : 8.0;

  static BorderRadius getBorderRadius(BuildContext context) =>
      BorderRadius.circular(isMobile(context) ? 8.0 : 12.0);

  static EdgeInsets getCardPadding(BuildContext context) =>
      EdgeInsets.all(isMobile(context) ? 16.0 : 24.0);

  static double getChartHeight(BuildContext context) =>
      isMobile(context) ? 150.0 : isTablet(context) ? 200.0 : 250.0;

  static double getIconSize(BuildContext context, double baseSize) =>
      isMobile(context) ? baseSize : baseSize * 1.2;

  static double getButtonHeight(BuildContext context) =>
      isMobile(context) ? 48.0 : 56.0;

  static TextStyle getHeadlineStyle(BuildContext context) =>
      TextStyle(
        fontSize: getFontSize(context, 24),
        fontWeight: FontWeight.bold,
        color: const Color(0xFF212121),
      );

  static TextStyle getBodyStyle(BuildContext context) =>
      TextStyle(
        fontSize: getFontSize(context, 16),
        color: const Color(0xFF757575),
      );

  static TextStyle getCaptionStyle(BuildContext context) =>
      TextStyle(
        fontSize: getFontSize(context, 12),
        color: const Color(0xFF9E9E9E),
      );
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);

    return builder(context, isMobile, isTablet, isDesktop);
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (Responsive.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 16.0,
    this.mainAxisSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: Responsive.getGridCrossAxisCount(context),
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double? mobile;
  final double? tablet;
  final double? desktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.isMobile(context)
        ? mobile ?? 16.0
        : Responsive.isTablet(context)
        ? tablet ?? 24.0
        : desktop ?? 32.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}







