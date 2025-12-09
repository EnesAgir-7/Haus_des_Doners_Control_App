import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:haus_des_control/Modules/inspector/widgets/custom_app_bar.dart';
import 'package:haus_des_control/core/constants/app_colors.dart';
import 'package:haus_des_control/core/constants/firebase_constants.dart';
import '../../../models/branch_update_request_model.dart';
import '../admin_providers/provider_admin_update_requests.dart';

class ScreenRequestDetails extends StatelessWidget {
  final BranchUpdateRequestModel request;

  const ScreenRequestDetails({Key? key, required this.request})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = request.isPending
        ? Colors.orange
        : request.isApproved
        ? Colors.green
        : Colors.red;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: const CustomAppBar(title: "Request Details"),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request Header
                  _buildRequestHeader(statusColor),
                  const SizedBox(height: 24),

                  // Changes Section
                  _buildSectionHeader('Requested Changes', Icons.edit_note),
                  const SizedBox(height: 16),
                  ...request.changes.entries.map((entry) {
                    return _buildChangeCard(entry.value);
                  }).toList(),

                  // Admin Note (if exists)
                  if (request.adminNote != null) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Admin Note', Icons.note),
                    const SizedBox(height: 16),
                    _buildAdminNote(request.adminNote!),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Action Buttons (only show for pending requests)
          if (request.isPending) _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildRequestHeader(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlack,
            AppColors.lightBlack.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.store, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.branchName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requested by ${request.requestedByName}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.edit_note,
                '${request.changeCount} ${request.changeCount == 1 ? 'Change' : 'Changes'}',
                AppColors.primaryRed,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.access_time,
                _formatDate(request.requestedAt),
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  request.isPending
                      ? Icons.pending_actions
                      : request.isApproved
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  request.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryRed, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildChangeCard(FieldChange change) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightBlack,
            AppColors.lightBlack.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field Name
            Row(
              children: [
                Icon(
                  _getFieldIcon(change.fieldType),
                  color: AppColors.primaryRed.withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  change.fieldName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Old Value
            _buildValueSection(
              'Old Value',
              change.oldValue,
              change.fieldType,
              Colors.red,
            ),
            const SizedBox(height: 12),

            // Divider with arrow
            Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_downward,
                    color: AppColors.primaryRed.withValues(alpha: 0.8),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.2)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // New Value
            _buildValueSection(
              'New Value',
              change.newValue,
              change.fieldType,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueSection(
    String label,
    dynamic value,
    String fieldType,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatValue(value, fieldType),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNote(String note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note, color: Colors.blue.withValues(alpha: 0.8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.0),
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Consumer<AdminUpdateRequestProvider>(
        builder: (context, provider, child) {
          return Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.isRejecting
                      ? null
                      : () => _showRejectDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: provider.isRejecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cancel, color: Colors.white),
                  label: Text(
                    provider.isRejecting ? 'Rejecting...' : 'Reject',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.isApproving
                      ? null
                      : () => _showApproveDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: provider.isApproving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle, color: Colors.white),
                  label: Text(
                    provider.isApproving ? 'Approving...' : 'Approve',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Request'),
        content: const Text('Are you sure you want to approve this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final adminId = loggedInUser?.id ?? '';

              final success = await context
                  .read<AdminUpdateRequestProvider>()
                  .approveRequest(
                    requestId: request.id,
                    branchId: request.branchId,
                    changes: request.changes,
                    adminNote: 'Approved',
                    adminId: adminId,
                    context: context,
                  );

              if (success && context.mounted) {
                Navigator.pop(context); // Go back to list
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.lightBlack,
        title: const Text(
          'Reject Request',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejecting this request:',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }

              Navigator.pop(dialogContext);

              final adminId = loggedInUser?.id ?? '';

              final success = await context
                  .read<AdminUpdateRequestProvider>()
                  .rejectRequest(
                    requestId: request.id,
                    adminNote: noteController.text.trim(),
                    adminId: adminId,
                    context: context,
                  );

              if (success && context.mounted) {
                Navigator.pop(context); // Go back to list
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  IconData _getFieldIcon(String fieldType) {
    switch (fieldType) {
      case 'geopoint':
        return Icons.location_on;
      case 'datetime':
        return Icons.calendar_today;
      case 'list':
        return Icons.list;
      case 'map':
        return Icons.view_module;
      default:
        return Icons.text_fields;
    }
  }

  String _formatValue(dynamic value, String fieldType) {
    if (value == null) return 'Not set';

    switch (fieldType) {
      case 'geopoint':
        if (value is GeoPoint) {
          return '${value.latitude.toStringAsFixed(6)}, ${value.longitude.toStringAsFixed(6)}';
        }
        return value.toString();

      case 'datetime':
        if (value is Timestamp) {
          return DateFormat('MMM dd, yyyy').format(value.toDate());
        } else if (value is DateTime) {
          return DateFormat('MMM dd, yyyy').format(value);
        }
        return value.toString();

      case 'list':
        if (value is List) {
          if (value.isEmpty) return 'Empty list';

          // Check if it's a list of maps (contact persons)
          if (value.first is Map) {
            return value
                .map((item) {
                  final map = item as Map<String, dynamic>;
                  return '• ${map['name']} (${map['phone']})';
                })
                .join('\n');
          }

          // Regular string list
          return value.map((item) => '• $item').join('\n');
        }
        return value.toString();

      case 'map':
        if (value is Map) {
          return value.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        }
        return value.toString();

      default:
        return value.toString();
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }
}
