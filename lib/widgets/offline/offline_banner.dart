import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// Offline mode banner that appears at the top of screens
/// Shows connectivity status and sync progress
class OfflineBanner extends StatefulWidget {
  final bool isOffline;
  final bool isSyncing;
  final int pendingChanges;
  final VoidCallback? onTapSync;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.isSyncing = false,
    this.pendingChanges = 0,
    this.onTapSync,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    if (widget.isOffline) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(OfflineBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOffline != oldWidget.isOffline) {
      if (widget.isOffline) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOffline && !widget.isSyncing) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation.drive(
        Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ),
      ),
      child: Material(
        elevation: 4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          decoration: BoxDecoration(
            color: widget.isSyncing
                ? AppColors.info
                : AppColors.warning,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (widget.isSyncing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.cloud_off,
                    color: Colors.white,
                    size: 20,
                  ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.isSyncing
                            ? 'Syncing...'
                            : 'You are offline',
                        style: AppTypography.labelLarge().copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.pendingChanges > 0)
                        Text(
                          '${widget.pendingChanges} pending ${widget.pendingChanges == 1 ? 'change' : 'changes'}',
                          style: AppTypography.labelSmall().copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!widget.isSyncing && widget.onTapSync != null)
                  TextButton(
                    onPressed: widget.onTapSync,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space12,
                        vertical: AppTheme.space8,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                    child: Text(
                      'Retry',
                      style: AppTypography.labelMedium().copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
