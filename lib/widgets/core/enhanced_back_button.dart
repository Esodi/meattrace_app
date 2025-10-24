import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EnhancedBackButton extends StatelessWidget {
  final String? fallbackRoute;

  const EnhancedBackButton({super.key, this.fallbackRoute});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else if (fallbackRoute != null) {
          context.go(fallbackRoute!);
        }
      },
    );
  }
}
