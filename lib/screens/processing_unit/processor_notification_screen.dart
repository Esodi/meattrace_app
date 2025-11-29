import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/notification/notification_list_item.dart';
import '../../widgets/notification/notification_badge.dart';

/// Processor notification list screen with filtering capabilities
class ProcessorNotificationScreen extends StatefulWidget {
  const ProcessorNotificationScreen({super.key});

  @override
  State<ProcessorNotificationScreen> createState() => _ProcessorNotificationScreenState();
}

class _ProcessorNotificationScreenState extends State<ProcessorNotificationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        title: Text(
          'Notifications',
          style: AppTypography.headlineMedium(),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return NotificationBadge(
                count: provider.unreadCount,
                showZero: false,
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Notification Settings',
                  color: AppColors.textPrimary,
                  onPressed: () => _showNotificationSettings(context),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Read'),
          ],
          labelStyle: AppTypography.button(),
          unselectedLabelStyle: AppTypography.button(),
          indicatorColor: AppColors.processorPrimary,
          labelColor: AppColors.processorPrimary,
          unselectedLabelColor: AppColors.textSecondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(NotificationFilter.all),
          _buildNotificationList(NotificationFilter.unread),
          _buildNotificationList(NotificationFilter.read),
        ],
      ),
      floatingActionButton: CustomFAB(
        icon: Icons.done_all,
        onPressed: () => _markAllAsRead(context),
        backgroundColor: AppColors.processorPrimary,
      ),
    );
  }

  Widget _buildNotificationList(NotificationFilter filter) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.processorPrimary,
            ),
          );
        }

        if (provider.error != null) {
          return _buildErrorState(provider.error!, provider);
        }

        final notifications = _getFilteredNotifications(provider, filter);

        if (notifications.isEmpty) {
          return _buildEmptyState(filter);
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshNotifications(),
          color: AppColors.processorPrimary,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppTheme.space16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space12),
                child: NotificationListItem(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onMarkAsRead: () => _markAsRead(notification.id),
                  onDelete: () => _deleteNotification(notification.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<NotificationModel> _getFilteredNotifications(
    NotificationProvider provider,
    NotificationFilter filter,
  ) {
    switch (filter) {
      case NotificationFilter.all:
        return provider.notifications;
      case NotificationFilter.unread:
        return provider.unreadNotifications;
      case NotificationFilter.read:
        return provider.readNotifications;
    }
  }

  Widget _buildEmptyState(NotificationFilter filter) {
    String message;
    String subtitle;
    IconData icon;

    switch (filter) {
      case NotificationFilter.all:
        message = 'No notifications yet';
        subtitle = 'You\'ll see updates about product rejections and processing here';
        icon = Icons.notifications_none;
        break;
      case NotificationFilter.unread:
        message = 'No unread notifications';
        subtitle = 'You\'re all caught up!';
        icon = Icons.notifications_active_outlined;
        break;
      case NotificationFilter.read:
        message = 'No read notifications';
        subtitle = 'Read notifications will appear here';
        icon = Icons.notifications_off_outlined;
        break;
    }

    return Center(
      child: EmptyStateCard(
        icon: icon,
        message: message,
        subtitle: subtitle,
        action: filter == NotificationFilter.all
            ? CustomButton(
                label: 'Refresh',
                onPressed: () => context.read<NotificationProvider>().refreshNotifications(),
                variant: ButtonVariant.primary,
                customColor: AppColors.processorPrimary,
              )
            : null,
      ),
    );
  }

  Widget _buildErrorState(String error, NotificationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              'Failed to load notifications',
              style: AppTypography.headlineMedium(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              error,
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space24),
            CustomButton(
              label: 'Try Again',
              onPressed: () => provider.refreshNotifications(),
              variant: ButtonVariant.primary,
              customColor: AppColors.processorPrimary,
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read if not already read
    if (!notification.isRead) {
      context.read<NotificationProvider>().markAsRead(notification.id);
    }

    // Handle action URL if present
    if (notification.actionUrl != null) {
      // Navigate to action URL or perform action
      _handleActionUrl(notification.actionUrl!);
    }
  }

  void _handleActionUrl(String actionUrl) {
    // Parse action URL and navigate accordingly
    if (actionUrl.startsWith('/')) {
      context.push(actionUrl);
    } else if (actionUrl.startsWith('http')) {
      // Handle external URLs
      // You might want to use url_launcher here
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    final success = await context.read<NotificationProvider>().markAsRead(notificationId);
    if (!success && mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark notification as read')),
        );
      }
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    final success = await context.read<NotificationProvider>().deleteNotification(notificationId);
    if (!success && mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete notification')),
        );
      }
    }
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    final success = await context.read<NotificationProvider>().markAllAsRead();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark all notifications as read')),
      );
    }
  }

  void _showNotificationSettings(BuildContext context) {
    // TODO: Implement notification settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings coming soon!')),
    );
  }
}

/// Notification filter enum
enum NotificationFilter {
  all,
  unread,
  read,
}
