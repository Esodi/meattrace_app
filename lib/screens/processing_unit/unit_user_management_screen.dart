import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../providers/processing_unit_management_provider.dart';
import '../../models/processing_unit_user.dart';
import '../../models/join_request.dart';
import '../../widgets/core/custom_button.dart';
import '../../widgets/core/custom_text_field.dart';

class ProcessingUnitUserManagementScreen extends StatefulWidget {
  final int unitId;
  
  const ProcessingUnitUserManagementScreen({
    super.key,
    required this.unitId,
  });

  @override
  State<ProcessingUnitUserManagementScreen> createState() =>
      _ProcessingUnitUserManagementScreenState();
}

class _ProcessingUnitUserManagementScreenState
    extends State<ProcessingUnitUserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProcessingUnitManagementProvider>();
      provider.loadUnitMembers(widget.unitId);
      provider.loadJoinRequests(widget.unitId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final provider = context.read<ProcessingUnitManagementProvider>();
    await provider.loadUnitMembers(widget.unitId);
    await provider.loadJoinRequests(widget.unitId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Unit Members',
          style: AppTypography.headlineMedium(color: Colors.white),
        ),
        backgroundColor: AppColors.processorPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.person_add, color: Colors.white),
            onPressed: _showInviteDialog,
            tooltip: 'Invite User',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: AppTypography.bodyLarge(color: Colors.white),
          unselectedLabelStyle: AppTypography.bodyMedium(color: Colors.white70),
          tabs: [
            Tab(
              icon: Icon(Icons.people, color: Colors.white),
              text: 'Active Members',
            ),
            Tab(
              icon: Icon(Icons.pending_actions, color: Colors.white),
              text: 'Pending Requests',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(),
                _buildRequestsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        icon: Icon(Icons.person_add),
        label: Text('Invite User'),
        backgroundColor: AppColors.processorPrimary,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(AppTheme.space16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search members...',
          prefixIcon: Icon(Icons.search, color: AppColors.processorPrimary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppColors.processorPrimary, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildMembersTab() {
    return Consumer<ProcessingUnitManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.processorPrimary),
          );
        }

        if (provider.error != null) {
          return _buildErrorState(provider.error!);
        }

        final members = _filterMembers(provider.members);

        if (members.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: _searchQuery.isEmpty ? 'No Members Yet' : 'No Members Found',
            message: _searchQuery.isEmpty
                ? 'Invite users to join your processing unit'
                : 'Try adjusting your search',
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.processorPrimary,
          child: ListView.builder(
            padding: EdgeInsets.all(AppTheme.space16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              return _buildMemberCard(members[index], provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return Consumer<ProcessingUnitManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.processorPrimary),
          );
        }

        if (provider.error != null) {
          return _buildErrorState(provider.error!);
        }

        final requests = provider.joinRequests;

        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.pending_actions_outlined,
            title: 'No Pending Requests',
            message: 'Join requests will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.processorPrimary,
          child: ListView.builder(
            padding: EdgeInsets.all(AppTheme.space16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(requests[index], provider);
            },
          ),
        );
      },
    );
  }

  List<ProcessingUnitUser> _filterMembers(List<ProcessingUnitUser> members) {
    if (_searchQuery.isEmpty) return members;
    
    return members.where((member) {
      return member.username.toLowerCase().contains(_searchQuery) ||
             member.email.toLowerCase().contains(_searchQuery) ||
             member.displayRole.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Widget _buildMemberCard(ProcessingUnitUser member, ProcessingUnitManagementProvider provider) {
    final canManage = provider.canManageUsers();
    
    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.space12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: () => _showMemberDetails(member),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.space16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _getRoleColor(member.role).withOpacity(0.2),
                child: Text(
                  member.username[0].toUpperCase(),
                  style: AppTypography.headlineMedium(
                    color: _getRoleColor(member.role),
                  ),
                ),
              ),
              SizedBox(width: AppTheme.space16),
              
              // Member info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.username,
                            style: AppTypography.bodyLarge().copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(member),
                      ],
                    ),
                    SizedBox(height: AppTheme.space4),
                    Text(
                      member.email,
                      style: AppTypography.bodyMedium(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppTheme.space8),
                    Row(
                      children: [
                        _buildRoleBadge(member.role),
                        SizedBox(width: AppTheme.space8),
                        Icon(
                          _getPermissionIcon(member.permissions),
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: AppTheme.space4),
                        Text(
                          member.permissions.toUpperCase(),
                          style: AppTypography.caption(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (member.lastActive != null) ...[
                      SizedBox(height: AppTheme.space4),
                      Text(
                        'Last active: ${_formatLastActive(member.lastActive!)}',
                        style: AppTypography.caption(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Actions menu
              if (canManage && !member.isOwner)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onSelected: (value) => _handleMemberAction(value, member, provider),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'change_role',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, color: AppColors.processorPrimary),
                          SizedBox(width: AppTheme.space8),
                          Text('Change Role'),
                        ],
                      ),
                    ),
                    if (member.isActive && !member.isSuspended)
                      PopupMenuItem(
                        value: 'suspend',
                        child: Row(
                          children: [
                            Icon(Icons.pause_circle, color: AppColors.warning),
                            SizedBox(width: AppTheme.space8),
                            Text('Suspend User'),
                          ],
                        ),
                      ),
                    if (member.isSuspended)
                      PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            Icon(Icons.play_circle, color: AppColors.success),
                            SizedBox(width: AppTheme.space8),
                            Text('Activate User'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.error),
                          SizedBox(width: AppTheme.space8),
                          Text('Remove User'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(JoinRequest request, ProcessingUnitManagementProvider provider) {
    final canManage = provider.canManageUsers();
    
    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.space12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: AppColors.processorPrimary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.processorPrimary.withOpacity(0.2),
                  child: Text(
                    (request.username ?? 'U')[0].toUpperCase(),
                    style: AppTypography.headlineMedium(
                      color: AppColors.processorPrimary,
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.username ?? 'No username',
                        style: AppTypography.bodyLarge().copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(request.email ?? 'No email',
                        style: AppTypography.bodyMedium(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.space12),
            
            Row(
              children: [
                Icon(Icons.work_outline, size: 16, color: AppColors.textSecondary),
                SizedBox(width: AppTheme.space4),
                Text(
                  'Requested Role: ',
                  style: AppTypography.bodyMedium(
                    color: AppColors.textSecondary,
                  ),
                ),
                _buildRoleBadge(request.requestedRole),
              ],
            ),
            
            if (request.message != null && request.message!.isNotEmpty) ...[
              SizedBox(height: AppTheme.space12),
              Container(
                padding: EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message:',
                      style: AppTypography.caption(
                        color: AppColors.textSecondary,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: AppTheme.space4),
                    Text(
                      request.message!,
                      style: AppTypography.bodyMedium(),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: AppTheme.space8),
            Text(
              'Requested: ${request.requestedAt != null ? _formatDate(request.requestedAt!) : 'Unknown'}',
              style: AppTypography.caption(
                color: AppColors.textSecondary,
              ),
            ),
            
            if (canManage) ...[
              SizedBox(height: AppTheme.space16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Reject',
                      onPressed: () => _handleRejectRequest(request, provider),
                      variant: ButtonVariant.secondary,
                      customColor: AppColors.error,
                      size: ButtonSize.small,
                    ),
                  ),
                  SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: CustomButton(
                      label: 'Approve',
                      onPressed: () => _handleApproveRequest(request, provider),
                      variant: ButtonVariant.primary,
                      customColor: AppColors.success,
                      size: ButtonSize.small,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ProcessingUnitUser member) {
    Color color;
    String status = member.status;
    
    if (member.isSuspended) {
      color = AppColors.error;
    } else if (!member.isActive) {
      color = AppColors.textSecondary;
    } else if (member.joinedAt == null) {
      color = AppColors.warning;
    } else {
      color = AppColors.success;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: AppTypography.caption(
          color: color,
        ).copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final color = _getRoleColor(role);
    final displayRole = role.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        displayRole,
        style: AppTypography.caption(
          color: color,
        ).copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: AppTheme.space24),
            Text(
              title,
              style: AppTypography.headlineMedium(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.space8),
            Text(
              message,
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            SizedBox(height: AppTheme.space24),
            Text(
              'Error Loading Data',
              style: AppTypography.headlineMedium(
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppTheme.space8),
            Text(
              error,
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.space24),
            CustomButton(
              label: 'Retry',
              onPressed: _refreshData,
              customColor: AppColors.processorPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return AppColors.processorPrimary;
      case 'manager':
        return Color(0xFF1976D2); // Blue
      case 'supervisor':
        return Color(0xFF7B1FA2); // Purple
      case 'quality_control':
        return Color(0xFFD84315); // Deep Orange
      case 'worker':
        return Color(0xFF455A64); // Blue Grey
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getPermissionIcon(String permission) {
    switch (permission) {
      case 'admin':
        return Icons.shield;
      case 'write':
        return Icons.edit;
      case 'read':
        return Icons.visibility;
      default:
        return Icons.help_outline;
    }
  }

  String _formatLastActive(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays < 1) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 2) {
      return 'Yesterday at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showMemberDetails(ProcessingUnitUser member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _buildMemberDetailsSheet(
          member,
          scrollController,
        ),
      ),
    );
  }

  Widget _buildMemberDetailsSheet(
    ProcessingUnitUser member,
    ScrollController scrollController,
  ) {
    return Container(
      padding: EdgeInsets.all(AppTheme.space24),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: AppTheme.space24),
          
          // Avatar and name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _getRoleColor(member.role).withOpacity(0.2),
                  child: Text(
                    member.username[0].toUpperCase(),
                    style: AppTypography.headlineLarge(
                      color: _getRoleColor(member.role),
                    ),
                  ),
                ),
                SizedBox(height: AppTheme.space16),
                Text(
                  member.username,
                  style: AppTypography.headlineMedium().copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppTheme.space4),
                Text(
                  member.email,
                  style: AppTypography.bodyMedium(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: AppTheme.space24),
          Divider(),
          SizedBox(height: AppTheme.space16),
          
          // Details
          _buildDetailRow('Role', member.displayRole),
          _buildDetailRow('Permissions', member.permissions.toUpperCase()),
          _buildDetailRow('Status', member.status),
          if (member.invitedByUsername != null)
            _buildDetailRow('Invited By', member.invitedByUsername!),
          _buildDetailRow('Invited At', _formatDate(member.invitedAt)),
          if (member.joinedAt != null)
            _buildDetailRow('Joined At', _formatDate(member.joinedAt!)),
          if (member.lastActive != null)
            _buildDetailRow('Last Active', _formatLastActive(member.lastActive!)),
          if (member.isSuspended && member.suspensionReason != null) ...[
            SizedBox(height: AppTheme.space16),
            Text(
              'Suspension Reason:',
              style: AppTypography.bodyLarge().copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: AppTheme.space8),
            Text(
              member.suspensionReason!,
              style: AppTypography.bodyMedium(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.space12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _handleMemberAction(
    String action,
    ProcessingUnitUser member,
    ProcessingUnitManagementProvider provider,
  ) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(member, provider);
        break;
      case 'suspend':
        _showSuspendDialog(member, provider);
        break;
      case 'activate':
        _handleActivateUser(member, provider);
        break;
      case 'remove':
        _showRemoveDialog(member, provider);
        break;
    }
  }

  void _showInviteDialog() {
    final emailController = TextEditingController();
    String selectedRole = 'worker';
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: AppColors.processorPrimary),
              SizedBox(width: AppTheme.space8),
              Text('Invite User'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: emailController,
                  label: 'Email Address',
                  hint: 'user@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(Icons.email),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppTheme.space16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'worker', child: Text('Worker')),
                    DropdownMenuItem(value: 'quality_control', child: Text('Quality Control')),
                    DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  ],
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            CustomButton(
              label: 'Send Invitation',
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _sendInvitation(
                    emailController.text.trim(),
                    selectedRole,
                  );
                }
              },
              customColor: AppColors.processorPrimary,
              size: ButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvitation(String email, String role) async {
    final provider = context.read<ProcessingUnitManagementProvider>();
    final success = await provider.inviteUser(
      unitId: widget.unitId,
      email: email,
      role: role,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Invitation sent successfully!'
                : provider.error ?? 'Failed to send invitation',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      
      if (success) {
        _refreshData();
      }
    }
  }

  void _showChangeRoleDialog(
    ProcessingUnitUser member,
    ProcessingUnitManagementProvider provider,
  ) {
    String selectedRole = member.role;
    String selectedPermission = member.permissions;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Role - ${member.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 'worker', child: Text('Worker')),
                  DropdownMenuItem(value: 'quality_control', child: Text('Quality Control')),
                  DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                ],
                onChanged: (value) => setState(() => selectedRole = value!),
              ),
              SizedBox(height: AppTheme.space16),
              DropdownButtonFormField<String>(
                value: selectedPermission,
                decoration: InputDecoration(
                  labelText: 'Permission Level',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 'read', child: Text('Read Only')),
                  DropdownMenuItem(value: 'write', child: Text('Read & Write')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) => setState(() => selectedPermission = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            CustomButton(
              label: 'Update Role',
              onPressed: () async {
                Navigator.pop(context);
                await _updateMemberRole(
                  member,
                  selectedRole,
                  selectedPermission,
                  provider,
                );
              },
              customColor: AppColors.processorPrimary,
              size: ButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateMemberRole(
    ProcessingUnitUser member,
    String newRole,
    String newPermission,
    ProcessingUnitManagementProvider provider,
  ) async {
    final success = await provider.updateMemberRole(
      unitId: widget.unitId,
      memberId: member.id,
      role: newRole,
      permission: newPermission,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Role updated successfully!'
                : provider.error ?? 'Failed to update role',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      
      if (success) {
        _refreshData();
      }
    }
  }

  void _showSuspendDialog(
    ProcessingUnitUser member,
    ProcessingUnitManagementProvider provider,
  ) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suspend User'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to suspend ${member.username}?',
                style: AppTypography.bodyMedium(),
              ),
              SizedBox(height: AppTheme.space16),
              CustomTextField(
                controller: reasonController,
                label: 'Reason for suspension',
                hint: 'Enter reason...',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          CustomButton(label: 'Suspend',
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                // TODO: Implement suspend functionality
                // This would require adding a suspend method to the provider
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Suspend functionality will be implemented soon'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            customColor: AppColors.warning,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  Future<void> _handleActivateUser(
    ProcessingUnitUser member,
    ProcessingUnitManagementProvider provider,
  ) async {
    // TODO: Implement activate functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Activate functionality will be implemented soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showRemoveDialog(
    ProcessingUnitUser member,
    ProcessingUnitManagementProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: AppTheme.space8),
            Text('Remove User'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${member.username} from this processing unit? This action cannot be undone.',
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          CustomButton(
            label: 'Remove',
            onPressed: () async {
              Navigator.pop(context);
              await _removeMember(member, provider);
            },
            customColor: AppColors.error,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(
    ProcessingUnitUser member,
    ProcessingUnitManagementProvider provider,
  ) async {
    final success = await provider.removeMember(unitId: widget.unitId, memberId: member.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'User removed successfully!'
                : provider.error ?? 'Failed to remove user',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      
      if (success) {
        _refreshData();
      }
    }
  }

  Future<void> _handleApproveRequest(
    JoinRequest request,
    ProcessingUnitManagementProvider provider,
  ) async {
    final success = await provider.approveJoinRequest(
      request.id!,
      responseMessage: 'Welcome to the team!',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Join request approved!'
                : provider.error ?? 'Failed to approve request',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      
      if (success) {
        _refreshData();
      }
    }
  }

  void _handleRejectRequest(
    JoinRequest request,
    ProcessingUnitManagementProvider provider,
  ) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Join Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reject join request from ${request.username}?',
                style: AppTypography.bodyMedium(),
              ),
              SizedBox(height: AppTheme.space16),
              CustomTextField(
                controller: reasonController,
                label: 'Reason (optional)',
                hint: 'Enter reason...',
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          CustomButton(
            label: 'Reject',
            onPressed: () async {
              Navigator.pop(context);
              await _rejectRequest(
                request,
                reasonController.text.trim(),
                provider,
              );
            },
            customColor: AppColors.error,
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRequest(
    JoinRequest request,
    String reason,
    ProcessingUnitManagementProvider provider,
  ) async {
    final success = await provider.rejectJoinRequest(
      request.id!,
      responseMessage: reason.isNotEmpty ? reason : 'Your request has been rejected.',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Join request rejected'
                : provider.error ?? 'Failed to reject request',
          ),
          backgroundColor: success ? AppColors.warning : AppColors.error,
        ),
      );
      
      if (success) {
        _refreshData();
      }
    }
  }
}
