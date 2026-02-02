import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  final Color? backgroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      elevation: 4.0,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
