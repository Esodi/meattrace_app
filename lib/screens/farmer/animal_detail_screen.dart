import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/animal_provider.dart';
import '../../models/animal.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_card.dart';
import '../../widgets/core/status_badge.dart';

/// Animal Detail View - Complete information about a single animal
/// Features: Photo, timeline, health records, actions
class AnimalDetailScreen extends StatefulWidget {
  final String animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Animal? _animal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnimal();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnimal() async {
    setState(() => _isLoading = true);
    try {
      final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
      await animalProvider.fetchAnimals(slaughtered: null);
      
      final animal = animalProvider.animals.firstWhere(
        (a) => a.id.toString() == widget.animalId,
        orElse: () => throw Exception('Animal not found'),
      );
      
      setState(() {
        _animal = animal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading animal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _animal == null
              ? _buildErrorState()
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildContent(),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.farmerPrimary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _animal?.animalName ?? _animal?.animalId ?? '',
          style: AppTypography.headlineSmall(color: Colors.white),
        ),
        background: _buildHeaderImage(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Home',
          onPressed: () => context.go('/farmer-home'),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Details')),
            const PopupMenuItem(value: 'slaughter', child: Text('Mark as Slaughtered')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.farmerPrimary,
            AppColors.farmerPrimary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getAnimalIcon(_animal?.species ?? ''),
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            StatusBadge(
              label: _getStatusLabel(),
              color: _getStatusColor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasicInfoSection(),
        const SizedBox(height: 16),
        _buildOriginSection(),
        const SizedBox(height: 16),
        _buildHealthSection(),
        const SizedBox(height: 16),
        _buildTimelineSection(),
        const SizedBox(height: 16),
        _buildActionsSection(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: AppTypography.headlineSmall()),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.fingerprint, 'Animal ID', _animal?.animalId ?? 'N/A'),
            const Divider(height: 24),
            _buildInfoRow(Icons.pets, 'Species', _animal?.species ?? 'N/A'),
            const Divider(height: 24),
            _buildInfoRow(Icons.category, 'Breed', _animal?.breed ?? 'N/A'),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              'Age',
              '${_animal?.age.toStringAsFixed(1) ?? 0} months',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.monitor_weight,
              'Weight',
              '${_animal?.liveWeight ?? 0} kg',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginSection() {
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Origin', style: AppTypography.headlineSmall()),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.agriculture,
              'Abbatoir',
              _animal?.abbatoirName ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              'Registered',
              _formatDate(_animal?.createdAt),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.person,
              'Farmer',
              _animal?.farmerUsername ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSection() {
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Health Records', style: AppTypography.headlineSmall()),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.health_and_safety,
              'Status',
              _getHealthStatusLabel(),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.event,
              'Registered',
              _formatDate(_animal?.createdAt),
            ),
            if (_animal?.slaughtered == true) ...[
              const Divider(height: 24),
              _buildInfoRow(
                Icons.warning,
                'Slaughtered',
                _formatDate(_animal?.slaughteredAt),
              ),
            ],
            if (_animal?.transferredTo != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                Icons.send,
                'Transferred',
                _formatDate(_animal?.transferredAt),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    final items = <Map<String, dynamic>>[];
    
    if (_animal?.slaughtered == true && _animal?.slaughteredAt != null) {
      items.add({
        'title': 'Slaughtered',
        'date': _formatDate(_animal?.slaughteredAt),
      });
    }
    
    if (_animal?.transferredTo != null && _animal?.transferredAt != null) {
      items.add({
        'title': 'Transferred to Processing Unit',
        'date': _formatDate(_animal?.transferredAt),
      });
    }
    
    items.add({
      'title': 'Animal Registered',
      'date': _formatDate(_animal?.createdAt),
    });
    
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timeline', style: AppTypography.headlineSmall()),
            const SizedBox(height: 24),
            ...items.asMap().entries.map((entry) {
              return _buildTimelineItem(
                entry.value['title'] as String,
                entry.value['date'] as String,
                entry.key == 0,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String date, bool isFirst) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isFirst ? AppColors.farmerPrimary : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
            ),
            if (!isFirst)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyLarge()),
              const SizedBox(height: 4),
              Text(
                date,
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    if (_animal == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Loading animal data...', style: AppTypography.bodyMedium(color: AppColors.textSecondary)),
      );
    }

    final bool canSlaughter = !_animal!.slaughtered;
    final bool isTransferred = _animal!.transferredTo != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status info
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: canSlaughter ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: canSlaughter ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Text(
              canSlaughter
                ? 'Animal is active and can be slaughtered'
                : isTransferred
                  ? 'Animal has been transferred and cannot be slaughtered'
                  : 'Animal has already been slaughtered',
              style: AppTypography.bodySmall(
                color: canSlaughter ? Colors.green : Colors.grey,
              ),
            ),
          ),

          // Action buttons
          if (canSlaughter)
            CustomButton(
              label: '🐄 Slaughter Animal',
              onPressed: _confirmSlaughter,
              variant: ButtonVariant.primary,
              customColor: Colors.orange,
              fullWidth: true,
              icon: Icons.set_meal,
            ),

          if (!canSlaughter)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isTransferred
                        ? 'This animal has been transferred to a processing unit'
                        : 'This animal has already been slaughtered',
                      style: AppTypography.bodyMedium(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          CustomButton(
            label: 'Delete Animal',
            onPressed: _confirmDelete,
            variant: ButtonVariant.text,
            customColor: Colors.red,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyLarge(),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          Text('Animal not found', style: AppTypography.displaySmall()),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Go Back',
            onPressed: () => context.pop(),
            variant: ButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        // Navigate to edit screen
        break;
      case 'slaughter':
        _confirmSlaughter();
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  Future<void> _confirmSlaughter() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Slaughtered'),
        content: Text(
          'Are you sure you want to mark ${_animal?.animalName ?? _animal?.animalId} as slaughtered? This will redirect you to the slaughter screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.push('/slaughter-animal?animalId=${_animal!.id}');
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Animal'),
        content: Text(
          'Are you sure you want to delete ${_animal?.animalName ?? _animal?.animalId}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final provider = Provider.of<AnimalProvider>(context, listen: false);
        await provider.deleteAnimal(_animal!.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Animal deleted successfully')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete animal: $e')),
          );
        }
      }
    }
  }

  IconData _getAnimalIcon(String species) {
    switch (species.toLowerCase()) {
      case 'cattle':
      case 'cow':
        return Icons.pets;
      case 'pig':
        return Icons.pets;
      case 'chicken':
        return Icons.egg;
      case 'sheep':
      case 'goat':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  String _getStatusLabel() {
    if (_animal?.slaughtered == true) return 'Slaughtered';
    if (_animal?.transferredTo != null) return 'Transferred';
    if (_animal?.healthStatus == 'sick') return 'Sick';
    if (_animal?.healthStatus == 'under_treatment') return 'Under Treatment';
    return 'Healthy • Active';
  }

  Color _getStatusColor() {
    if (_animal?.slaughtered == true) return Colors.grey;
    if (_animal?.transferredTo != null) return Colors.blue;
    if (_animal?.healthStatus == 'sick') return Colors.red;
    if (_animal?.healthStatus == 'under_treatment') return Colors.orange;
    return Colors.green;
  }

  String _getHealthStatusLabel() {
    final healthStatus = _animal?.healthStatus ?? 'healthy';
    switch (healthStatus) {
      case 'sick':
        return '⚠️ Sick';
      case 'under_treatment':
        return '🔄 Under Treatment';
      default:
        return '✓ Healthy';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
