import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';

/// MeatTrace Pro - Role Avatar Components
/// Profile avatars with role-based colors and initials

enum AvatarSize {
  extraSmall, // 24px
  small,      // 32px
  medium,     // 40px
  large,      // 56px
  extraLarge, // 72px
}

/// Base Role Avatar
class RoleAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final String? role; // 'farmer', 'processing_unit', 'shop', 'admin'
  final AvatarSize size;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool showOnlineIndicator;
  final bool isOnline;

  const RoleAvatar({
    Key? key,
    this.name,
    this.imageUrl,
    this.role,
    this.size = AvatarSize.medium,
    this.onTap,
    this.showBorder = false,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Size configurations
    double avatarSize;
    double fontSize;
    double borderWidth;
    double indicatorSize;

    switch (size) {
      case AvatarSize.extraSmall:
        avatarSize = 24;
        fontSize = 10;
        borderWidth = 1.5;
        indicatorSize = 6;
        break;
      case AvatarSize.small:
        avatarSize = 32;
        fontSize = 12;
        borderWidth = 2;
        indicatorSize = 8;
        break;
      case AvatarSize.medium:
        avatarSize = 40;
        fontSize = 14;
        borderWidth = 2;
        indicatorSize = 10;
        break;
      case AvatarSize.large:
        avatarSize = 56;
        fontSize = 18;
        borderWidth = 3;
        indicatorSize = 12;
        break;
      case AvatarSize.extraLarge:
        avatarSize = 72;
        fontSize = 24;
        borderWidth = 3;
        indicatorSize = 14;
        break;
    }

    // Get role-based color
    Color backgroundColor = role != null
        ? AppColors.getPrimaryColorForRole(role!)
        : (isDark ? AppColors.darkSurfaceVariant : AppColors.backgroundGray);

    // Get initials from name
    String initials = _getInitials(name);

    Widget avatar = Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: isDark ? AppColors.darkDivider : Colors.white,
                width: borderWidth,
              )
            : null,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initials,
                style: AppTypography.labelLarge(color: Colors.white).copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );

    // Wrap with online indicator if needed
    if (showOnlineIndicator) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: indicatorSize,
              height: indicatorSize,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.textSecondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Wrap with tap handler if provided
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(avatarSize / 2),
        child: avatar,
      );
    }

    return avatar;
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
  }
}

/// Avatar Group - Display multiple avatars in a row
class AvatarGroup extends StatelessWidget {
  final List<AvatarData> avatars;
  final AvatarSize size;
  final int maxVisible;
  final double overlap; // Percentage of overlap (0.0 to 1.0)
  final VoidCallback? onMoreTap;

  const AvatarGroup({
    Key? key,
    required this.avatars,
    this.size = AvatarSize.small,
    this.maxVisible = 3,
    this.overlap = 0.3,
    this.onMoreTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visibleAvatars = avatars.take(maxVisible).toList();
    final remainingCount = avatars.length - maxVisible;

    // Calculate avatar size
    double avatarSize;
    switch (size) {
      case AvatarSize.extraSmall:
        avatarSize = 24;
        break;
      case AvatarSize.small:
        avatarSize = 32;
        break;
      case AvatarSize.medium:
        avatarSize = 40;
        break;
      case AvatarSize.large:
        avatarSize = 56;
        break;
      case AvatarSize.extraLarge:
        avatarSize = 72;
        break;
    }

    final overlapAmount = avatarSize * overlap;

    return SizedBox(
      height: avatarSize,
      child: Stack(
        children: [
          ...visibleAvatars.asMap().entries.map((entry) {
            final index = entry.key;
            final avatar = entry.value;

            return Positioned(
              left: index * (avatarSize - overlapAmount),
              child: RoleAvatar(
                name: avatar.name,
                imageUrl: avatar.imageUrl,
                role: avatar.role,
                size: size,
                showBorder: true,
                onTap: avatar.onTap,
              ),
            );
          }),
          if (remainingCount > 0)
            Positioned(
              left: visibleAvatars.length * (avatarSize - overlapAmount),
              child: _MoreAvatar(
                count: remainingCount,
                size: avatarSize,
                onTap: onMoreTap,
              ),
            ),
        ],
      ),
    );
  }
}

/// Data class for avatar information
class AvatarData {
  final String? name;
  final String? imageUrl;
  final String? role;
  final VoidCallback? onTap;

  const AvatarData({
    this.name,
    this.imageUrl,
    this.role,
    this.onTap,
  });
}

/// More Avatar - Shows "+N" for remaining avatars
class _MoreAvatar extends StatelessWidget {
  final int count;
  final double size;
  final VoidCallback? onTap;

  const _MoreAvatar({
    required this.count,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.backgroundGray,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkDivider : Colors.white,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: AppTypography.labelMedium(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ).copyWith(
            fontSize: size * 0.3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: avatar,
      );
    }

    return avatar;
  }
}

/// Avatar with name and subtitle
class AvatarWithDetails extends StatelessWidget {
  final String? name;
  final String? subtitle;
  final String? imageUrl;
  final String? role;
  final AvatarSize avatarSize;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showOnlineIndicator;
  final bool isOnline;

  const AvatarWithDetails({
    Key? key,
    this.name,
    this.subtitle,
    this.imageUrl,
    this.role,
    this.avatarSize = AvatarSize.medium,
    this.onTap,
    this.trailing,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        child: Row(
          children: [
            RoleAvatar(
              name: name,
              imageUrl: imageUrl,
              role: role,
              size: avatarSize,
              showOnlineIndicator: showOnlineIndicator,
              isOnline: isOnline,
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name != null)
                    Text(
                      name!,
                      style: AppTypography.bodyLarge(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppTheme.space12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon Avatar - Avatar with icon instead of initials
class IconAvatar extends StatelessWidget {
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final AvatarSize size;
  final VoidCallback? onTap;

  const IconAvatar({
    Key? key,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.size = AvatarSize.medium,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Size configurations
    double avatarSize;
    double iconSize;

    switch (size) {
      case AvatarSize.extraSmall:
        avatarSize = 24;
        iconSize = 12;
        break;
      case AvatarSize.small:
        avatarSize = 32;
        iconSize = 16;
        break;
      case AvatarSize.medium:
        avatarSize = 40;
        iconSize = 20;
        break;
      case AvatarSize.large:
        avatarSize = 56;
        iconSize = 28;
        break;
      case AvatarSize.extraLarge:
        avatarSize = 72;
        iconSize = 36;
        break;
    }

    Widget avatar = Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor ?? theme.colorScheme.onPrimaryContainer,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(avatarSize / 2),
        child: avatar,
      );
    }

    return avatar;
  }
}
