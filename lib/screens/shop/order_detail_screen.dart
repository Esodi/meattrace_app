import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../services/dio_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_theme.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/status_badge.dart';

/// Modern Order Detail Screen
/// Features: Order timeline, items list, delivery info, actions
class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = false;
  Order? _order;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient().dio;
      final response = await dio.get('/orders/${widget.orderId}/');
      
      setState(() {
        _order = Order.fromJson(response.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading order: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text('Cancel Order?', style: AppTypography.headlineMedium()),
        content: Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No', style: AppTypography.button()),
          ),
          CustomButton(
            label: 'Yes, Cancel',
            customColor: AppColors.error,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final dio = DioClient().dio;
      await dio.patch(
        '/orders/${widget.orderId}/',
        data: {'status': 'cancelled'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadOrderDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'preparing':
        return AppColors.processorPrimary;
      case 'ready':
        return AppColors.success;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Details', style: AppTypography.headlineMedium()),
            if (_order != null)
              Text(
                'Order #${_order!.id}',
                style: AppTypography.bodySmall().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          if (_order != null && _order!.status.toLowerCase() != 'cancelled' && _order!.status.toLowerCase() != 'delivered')
            IconButton(
              icon: Icon(Icons.cancel, color: AppColors.error),
              tooltip: 'Cancel Order',
              onPressed: _cancelOrder,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.shopPrimary),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _order == null
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadOrderDetails,
                      color: AppColors.shopPrimary,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOrderHeader(),
                            const SizedBox(height: AppTheme.space16),
                            _buildOrderTimeline(),
                            const SizedBox(height: AppTheme.space16),
                            _buildOrderItems(),
                            const SizedBox(height: AppTheme.space16),
                            _buildDeliveryInfo(),
                            if (_order!.notes != null && _order!.notes!.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.space16),
                              _buildNotes(),
                            ],
                            const SizedBox(height: AppTheme.space16),
                            _buildActionButtons(),
                            const SizedBox(height: AppTheme.space24),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildOrderHeader() {
    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppColors.shopPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: AppColors.shopPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${_order!.id}',
                      style: AppTypography.titleLarge(),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      DateFormat('MMM dd, yyyy - hh:mm a').format(_order!.createdAt),
                      style: AppTypography.bodySmall().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: _order!.status.toUpperCase(),
                color: _getStatusColor(_order!.status),
              ),
            ],
          ),
          const Divider(height: AppTheme.space24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: AppTypography.titleMedium(),
              ),
              Text(
                '\$${_order!.totalAmount.toStringAsFixed(2)}',
                style: AppTypography.headlineLarge().copyWith(
                  color: AppColors.shopPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline() {
    final statuses = ['pending', 'confirmed', 'preparing', 'ready', 'delivered'];
    final currentIndex = statuses.indexOf(_order!.status.toLowerCase());
    final isCancelled = _order!.status.toLowerCase() == 'cancelled';

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: AppTheme.space16),
          if (isCancelled)
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, color: AppColors.error),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Cancelled',
                          style: AppTypography.titleMedium().copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          'This order has been cancelled',
                          style: AppTypography.bodySmall().copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: List.generate(statuses.length, (index) {
                final status = statuses[index];
                final isCompleted = index <= currentIndex;
                final isCurrent = index == currentIndex;

                return _buildTimelineItem(
                  label: status[0].toUpperCase() + status.substring(1),
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  isLast: index == statuses.length - 1,
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String label,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : AppColors.textSecondary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? AppColors.shopPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                color: isCompleted ? Colors.white : AppColors.textSecondary,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? AppColors.success
                    : AppColors.textSecondary.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.titleMedium().copyWith(
                  color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isCurrent)
                Text(
                  'In Progress',
                  style: AppTypography.bodySmall().copyWith(
                    color: AppColors.shopPrimary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: AppTheme.space16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _order!.items.length,
            separatorBuilder: (context, index) => const Divider(height: AppTheme.space16),
            itemBuilder: (context, index) {
              final item = _order!.items[index];
              return Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.shopPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: AppColors.shopPrimary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product #${item.product}',
                          style: AppTypography.titleMedium(),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                          style: AppTypography.bodySmall().copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${item.subtotal.toStringAsFixed(2)}',
                    style: AppTypography.titleMedium().copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(height: AppTheme.space24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.titleLarge().copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${_order!.totalAmount.toStringAsFixed(2)}',
                style: AppTypography.titleLarge().copyWith(
                  color: AppColors.shopPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Information',
            style: AppTypography.titleMedium(),
          ),
          const SizedBox(height: AppTheme.space16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.shopPrimary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: AppTypography.labelMedium().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      _order!.deliveryAddress ?? 'Not specified',
                      style: AppTypography.bodyMedium(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: AppColors.shopPrimary, size: 20),
              const SizedBox(width: AppTheme.space8),
              Text(
                'Order Notes',
                style: AppTypography.titleMedium(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              _order!.notes!,
              style: AppTypography.bodyMedium(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canCancel = _order!.status.toLowerCase() != 'cancelled' &&
        _order!.status.toLowerCase() != 'delivered';

    return Column(
      children: [
        if (canCancel)
          CustomButton(
            label: 'Cancel Order',
            customColor: AppColors.error,
            onPressed: _cancelOrder,
          ),
        if (canCancel) const SizedBox(height: AppTheme.space12),
        CustomButton(
          label: 'Contact Support',
          variant: ButtonVariant.secondary,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Contact support feature coming soon'),
                backgroundColor: AppColors.info,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              'Error Loading Order',
              style: AppTypography.headlineMedium(),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              _errorMessage ?? 'An error occurred',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space24),
            CustomButton(
              label: 'Try Again',
              onPressed: _loadOrderDetails,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space24),
              decoration: BoxDecoration(
                color: AppColors.shopPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: AppColors.shopPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              'Order Not Found',
              style: AppTypography.headlineMedium(),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'The order you are looking for does not exist',
              style: AppTypography.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space24),
            CustomButton(
              label: 'Go Back',
              variant: ButtonVariant.secondary,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
