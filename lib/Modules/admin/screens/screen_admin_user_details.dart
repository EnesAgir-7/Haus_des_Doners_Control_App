// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:haus_des_control/Modules/inspector/widgets/custom_toast.dart';
// import 'package:provider/provider.dart';

// import '../../../core/constants/app_colors.dart';
// import '../../../models/branch_model.dart';
// import '../../../models/user_model.dart';
// import '../../../models/vehicle_model.dart';
// import '../../../translations/locale_keys.g.dart';
// import '../../inspector/widgets/app_button.dart';
// import '../admin_providers/provider_admin_users.dart';

// class ScreenAdminUserDetails extends StatefulWidget {
//   final UserModel inspector;

//   const ScreenAdminUserDetails({super.key, required this.inspector});

//   @override
//   State<ScreenAdminUserDetails> createState() => _ScreenAdminUserDetailsState();
// }

// class _ScreenAdminUserDetailsState extends State<ScreenAdminUserDetails> {
//   late TextEditingController _nameController;
//   late TextEditingController _emailController;
//   late TextEditingController _regionController;

//   bool _isEditing = false;
//   List<BranchModel> _assignedBranches = [];
//   List<VehicleModel> _assignedVehicles = [];
//   bool _isLoadingDetails = true;
//   String? _detailsError;

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.inspector.name);
//     _emailController = TextEditingController(
//       text: widget.inspector.serviceAccount,
//     );
//     _regionController = TextEditingController(
//       text: widget.inspector.region ?? '',
//     );
//     _loadInspectorDetails();
//   }

//   Future<void> _loadInspectorDetails() async {
//     try {
//       _isLoadingDetails = true;
//       _detailsError = null;
//       if (mounted) setState(() {});

//       final provider = context.read<ProviderAdminUsers>();
//       final details = await provider.getInspectorDetails(widget.inspector.id);

//       _assignedBranches = details['branches'];
//       _assignedVehicles = details['vehicles'];
//       _isLoadingDetails = false;
//       if (mounted) setState(() {});
//     } catch (e) {
//       _detailsError = e.toString();
//       _isLoadingDetails = false;
//       if (mounted) setState(() {});
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _regionController.dispose();
//     super.dispose();
//   }

//   void _toggleEdit() {
//     if (_isEditing) {
//       _nameController.text = widget.inspector.name;
//       _emailController.text = widget.inspector.serviceAccount;
//       _regionController.text = widget.inspector.region ?? '';
//     }
//     setState(() => _isEditing = !_isEditing);
//   }

//   Future<void> _saveChanges() async {
//     final provider = context.read<ProviderAdminUsers>();
//     try {
//       await provider.updateInspector(widget.inspector.id, {
//         'name': _nameController.text,
//         'email': _emailController.text,
//         'region': _regionController.text.isEmpty
//             ? null
//             : _regionController.text,
//       });

//       if (mounted) {
//         setState(() => _isEditing = false);
//         showSnakBarr(context, LocaleKeys.user_updated_successfully.tr());
//       }
//     } catch (e) {
//       if (mounted) {
//         showSnakBarr(context, 'Error: $e');
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               AppColors.primaryRed.withValues(alpha: 0.08),
//               AppColors.primaryDark,
//               AppColors.primaryDark,
//             ],
//             stops: const [0.0, 0.25, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           child: _isLoadingDetails ? _buildLoadingState() : _buildContent(),
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingState() {
//     return Center(
//       child: CircularProgressIndicator(color: AppColors.primaryRed),
//     );
//   }

//   Widget _buildContent() {
//     if (_detailsError != null) {
//       return _buildErrorState();
//     }

//     return RefreshIndicator(
//       onRefresh: _loadInspectorDetails,
//       color: AppColors.primaryRed,
//       backgroundColor: AppColors.lightBlack,
//       child: CustomScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         slivers: [
//           _buildAppBar(),
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildProfileSection(),
//                   const SizedBox(height: 24),
//                   _buildStatsCards(),
//                   const SizedBox(height: 24),
//                   _buildBasicInfoSection(),
//                   const SizedBox(height: 24),
//                   Container(height: 1, color: Colors.white24),
//                   const SizedBox(height: 24),
//                   _buildVehiclesSection(),
//                   const SizedBox(height: 24),
//                   Container(height: 1, color: Colors.white24),
//                   const SizedBox(height: 24),
//                   _buildBranchesSection(),
//                   const SizedBox(height: 80),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 60, color: AppColors.primaryRed),
//             const SizedBox(height: 16),
//             Text(
//               LocaleKeys.error_occurred.tr(),
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _detailsError!,
//               style: const TextStyle(color: Colors.white70),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _loadInspectorDetails,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primaryRed,
//               ),
//               child: Text(LocaleKeys.try_again.tr()),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     return SliverAppBar(
//       expandedHeight: 0,
//       floating: true,
//       pinned: false,
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back, color: Colors.white),
//         onPressed: () => Navigator.pop(context),
//       ),
//       actions: [
//         IconButton(
//           icon: Icon(
//             _isEditing ? Icons.close : Icons.edit,
//             color: Colors.white,
//           ),
//           onPressed: _toggleEdit,
//         ),
//         if (_isEditing)
//           Consumer<ProviderAdminUsers>(
//             builder: (context, provider, _) {
//               return IconButton(
//                 icon: provider.isLoading
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : const Icon(Icons.save, color: Colors.white),
//                 onPressed: provider.isLoading ? null : _saveChanges,
//               );
//             },
//           ),
//       ],
//     );
//   }

//   Widget _buildProfileSection() {
//     return Center(
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(4),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: AppColors.primaryRed, width: 3),
//             ),
//             child: CircleAvatar(
//               radius: 50,
//               backgroundColor: AppColors.lightRed,
//               child: Text(
//                 widget.inspector.name[0].toUpperCase(),
//                 style: const TextStyle(
//                   fontSize: 40,
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             widget.inspector.name,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             widget.inspector.serviceAccount,
//             style: const TextStyle(color: Colors.white70, fontSize: 14),
//           ),
//           const SizedBox(height: 12),
//           _buildStatusBadge(),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusBadge() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: widget.inspector.active
//             ? Colors.green.withValues(alpha: 0.2)
//             : Colors.grey.withValues(alpha: 0.2),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: widget.inspector.active ? Colors.green : Colors.grey,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             widget.inspector.active ? Icons.check_circle : Icons.cancel,
//             size: 16,
//             color: widget.inspector.active ? Colors.green : Colors.grey,
//           ),
//           const SizedBox(width: 6),
//           Text(
//             widget.inspector.active
//                 ? LocaleKeys.active.tr()
//                 : LocaleKeys.inactive.tr(),
//             style: TextStyle(
//               color: widget.inspector.active ? Colors.green : Colors.grey,
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsCards() {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildStatCard(
//             label: LocaleKeys.assigned_branches.tr(),
//             value: _assignedBranches.length.toString(),
//             icon: Icons.location_on,
//             color: Colors.blue,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _buildStatCard(
//             label: 'Vehicles',
//             value: _assignedVehicles.length.toString(),
//             icon: Icons.directions_car,
//             color: Colors.amber,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard({
//     required String label,
//     required String value,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.lightRed,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white24),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 28),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: const TextStyle(color: Colors.white70, fontSize: 12),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBasicInfoSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.person_outline, color: AppColors.primaryRed, size: 20),
//             const SizedBox(width: 8),
//             Text(
//               'Basic Information',
//               style: TextStyle(
//                 color: AppColors.primaryRed,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         _buildInfoField(
//           label: LocaleKeys.name.tr(),
//           controller: _nameController,
//           enabled: _isEditing,
//           icon: Icons.person,
//         ),
//         const SizedBox(height: 12),
//         _buildInfoField(
//           label: LocaleKeys.email.tr(),
//           controller: _emailController,
//           enabled: _isEditing,
//           readOnly: true,
//           icon: Icons.email,
//           keyboardType: TextInputType.emailAddress,
//         ),
//         const SizedBox(height: 12),
//         _buildInfoField(
//           label: LocaleKeys.region.tr(),
//           controller: _regionController,
//           enabled: _isEditing,
//           icon: Icons.location_city,
//         ),
//         const SizedBox(height: 12),
//         _buildInfoTile(
//           label: LocaleKeys.role.tr(),
//           value: widget.inspector.role.toUpperCase(),
//           icon: Icons.badge,
//           valueColor: Colors.blue,
//         ),
//       ],
//     );
//   }

//   Widget _buildInfoField({
//     required String label,
//     required TextEditingController controller,
//     required bool enabled,
//     required IconData icon,
//     TextInputType? keyboardType,
//     bool readOnly = false,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.lightBlack,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: enabled ? AppColors.primaryRed : Colors.white24,
//         ),
//       ),
//       child: TextField(
//         readOnly: readOnly,
//         controller: controller,
//         enabled: enabled,
//         keyboardType: keyboardType,
//         style: TextStyle(color: enabled ? Colors.white : Colors.white70),
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: TextStyle(
//             color: enabled ? AppColors.primaryRed : Colors.white54,
//           ),
//           prefixIcon: Icon(
//             icon,
//             color: enabled ? AppColors.primaryRed : Colors.white54,
//             size: 20,
//           ),
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 14,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoTile({
//     required String label,
//     required String value,
//     required IconData icon,
//     Color? valueColor,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.lightBlack,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white24),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.white54, size: 20),
//           const SizedBox(width: 12),
//           Text(
//             label,
//             style: const TextStyle(color: Colors.white70, fontSize: 14),
//           ),
//           const Spacer(),
//           Text(
//             value,
//             style: TextStyle(
//               color: valueColor ?? Colors.white,
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVehiclesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   Icons.directions_car,
//                   color: AppColors.primaryRed,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Assigned Vehicles',
//                   style: TextStyle(
//                     color: AppColors.primaryRed,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 color: AppColors.lightRed,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 _assignedVehicles.length.toString(),
//                 style: TextStyle(
//                   color: AppColors.primaryRed,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         if (_assignedVehicles.isEmpty)
//           _buildEmptyState(
//             icon: Icons.directions_car,
//             message: 'No vehicles assigned',
//             actionText: 'Assign Vehicle',
//             onAction: _showAssignVehicleDialog,
//           )
//         else
//           Column(
//             children: [
//               ..._assignedVehicles.map((vehicle) => _buildVehicleCard(vehicle)),
//               const SizedBox(height: 12),
//               AppButton(
//                 text: 'Assign Another Vehicle',
//                 onPressed: _showAssignVehicleDialog,
//                 textStyle: TextStyle(
//                   color: AppColors.primaryDark,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 borderRadius: 10,
//               ),
//             ],
//           ),
//       ],
//     );
//   }

//   Widget _buildVehicleCard(VehicleModel vehicle) {
//     return Consumer<ProviderAdminUsers>(
//       builder: (context, provider, _) {
//         return Container(
//           margin: const EdgeInsets.only(bottom: 12),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: AppColors.lightBlack,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.white24),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: AppColors.lightRed,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(
//                   Icons.directions_car,
//                   color: AppColors.primaryRed,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       vehicle.model,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       vehicle.plate,
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(
//                   Icons.remove_circle_outline,
//                   color: Colors.red,
//                 ),
//                 onPressed: provider.isLoading
//                     ? null
//                     : () => _unassignVehicle(vehicle.id),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildBranchesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.location_on, color: AppColors.primaryRed, size: 20),
//                 const SizedBox(width: 8),
//                 Text(
//                   LocaleKeys.assigned_branches.tr(),
//                   style: TextStyle(
//                     color: AppColors.primaryRed,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 color: AppColors.lightRed,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 _assignedBranches.length.toString(),
//                 style: TextStyle(
//                   color: AppColors.primaryRed,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         if (_assignedBranches.isEmpty)
//           _buildEmptyState(
//             icon: Icons.apartment,
//             message: 'No branches assigned',
//             actionText: 'Assign Branch',
//             onAction: _showAssignBranchDialog,
//           )
//         else
//           Column(
//             children: [
//               ..._assignedBranches.map((branch) => _buildBranchCard(branch)),
//               const SizedBox(height: 12),
//               AppButton(
//                 text: 'Assign Another Branch',
//                 onPressed: _showAssignBranchDialog,
//                 textStyle: TextStyle(
//                   color: AppColors.primaryDark,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 borderRadius: 10,
//               ),
//             ],
//           ),
//       ],
//     );
//   }

//   Widget _buildBranchCard(BranchModel branch) {
//     return Consumer<ProviderAdminUsers>(
//       builder: (context, provider, _) {
//         return Container(
//           margin: const EdgeInsets.only(bottom: 12),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: AppColors.lightBlack,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.white24),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: AppColors.lightRed,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(
//                   Icons.location_on,
//                   color: AppColors.primaryRed,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       branch.name,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       branch.address,
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 13,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     if (branch.region != null) ...[
//                       const SizedBox(height: 2),
//                       Text(
//                         'Region: ${branch.region}',
//                         style: const TextStyle(
//                           color: Colors.white54,
//                           fontSize: 11,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(
//                   Icons.remove_circle_outline,
//                   color: Colors.red,
//                 ),
//                 onPressed: provider.isLoading
//                     ? null
//                     : () => _unassignBranch(branch.id),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState({
//     required IconData icon,
//     required String message,
//     required String actionText,
//     required VoidCallback onAction,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: AppColors.lightBlack,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white24),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, size: 48, color: Colors.white24),
//           const SizedBox(height: 12),
//           Text(
//             message,
//             style: const TextStyle(color: Colors.white54, fontSize: 14),
//           ),
//           const SizedBox(height: 16),
//           AppButton(
//             text: actionText,
//             onPressed: onAction,
//             backgroundColor: AppColors.primaryRed,
//             textStyle: const TextStyle(
//               color: Colors.white,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//             borderRadius: 10,
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _showAssignBranchDialog() async {
//     final provider = context.read<ProviderAdminUsers>();

//     try {
//       final unassignedBranches = await provider.getUnassignedBranches();

//       if (!mounted) return;

//       if (unassignedBranches.isEmpty) {
//         showSnakBarr(context, 'No unassigned branches available');

//         return;
//       }

//       final selected = await showModalBottomSheet<BranchModel>(
//         context: context,
//         backgroundColor: AppColors.lightBlack,
//         isScrollControlled: true,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         builder: (context) => _buildSelectionSheet(
//           title: 'Select Branch to Assign',
//           items: unassignedBranches,
//           itemBuilder: (branch) => ListTile(
//             leading: const Icon(Icons.location_on, color: AppColors.primaryRed),
//             title: Text(
//               branch.name,
//               style: const TextStyle(color: Colors.white),
//             ),
//             subtitle: Text(
//               branch.address,
//               style: const TextStyle(color: Colors.white70),
//             ),
//             onTap: () => Navigator.pop(context, branch),
//           ),
//         ),
//       );

//       if (selected != null && mounted) {
//         try {
//           await provider.assignBranchToInspector(
//             widget.inspector.id,
//             selected.id,
//           );
//           await _loadInspectorDetails();
//           if (mounted) {
//             showSnakBarr(context, 'Branch assigned successfully');
//           }
//         } catch (e) {
//           if (mounted) {
//             showSnakBarr(context, 'Error: $e');
//           }
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         showSnakBarr(context, 'Error loading branches:: $e');
//       }
//     }
//   }

//   Future<void> _showAssignVehicleDialog() async {
//     final provider = context.read<ProviderAdminUsers>();

//     try {
//       final unassignedVehicles = await provider.getUnassignedVehicles();

//       if (!mounted) return;

//       if (unassignedVehicles.isEmpty) {
//         showSnakBarr(context, 'No unassigned vehicles available');

//         return;
//       }

//       final selected = await showModalBottomSheet<VehicleModel>(
//         context: context,
//         backgroundColor: AppColors.lightBlack,
//         isScrollControlled: true,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         builder: (context) => _buildSelectionSheet(
//           title: 'Select Vehicle to Assign',
//           items: unassignedVehicles,
//           itemBuilder: (vehicle) => ListTile(
//             leading: const Icon(
//               Icons.directions_car,
//               color: AppColors.primaryRed,
//             ),
//             title: Text(
//               vehicle.model,
//               style: const TextStyle(color: Colors.white),
//             ),
//             subtitle: Text(
//               vehicle.plate,
//               style: const TextStyle(color: Colors.white70),
//             ),
//             onTap: () => Navigator.pop(context, vehicle),
//           ),
//         ),
//       );

//       if (selected != null && mounted) {
//         try {
//           await provider.assignVehicleToInspector(
//             widget.inspector.id,
//             selected.id,
//           );
//           await _loadInspectorDetails();
//           if (mounted) {
//             showSnakBarr(context, 'Vehicle assigned successfully');
//           }
//         } catch (e) {
//           if (mounted) {
//             showSnakBarr(context, 'Error: $e');
//           }
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         showSnakBarr(context, 'Error loading vehicles: $e');
//       }
//     }
//   }

//   Widget _buildSelectionSheet<T>({
//     required String title,
//     required List<T> items,
//     required Widget Function(T) itemBuilder,
//   }) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.6,
//       minChildSize: 0.3,
//       maxChildSize: 0.9,
//       expand: false,
//       builder: (context, scrollController) {
//         return Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               Center(
//                 child: Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.white24,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Expanded(
//                 child: items.isEmpty
//                     ? const Center(
//                         child: Text(
//                           'No items available',
//                           style: TextStyle(color: Colors.white54),
//                         ),
//                       )
//                     : ListView.builder(
//                         controller: scrollController,
//                         itemCount: items.length,
//                         itemBuilder: (context, index) {
//                           return itemBuilder(items[index]);
//                         },
//                       ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<void> _unassignBranch(String branchId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: AppColors.lightBlack,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text(
//           'Unassign Branch',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: const Text(
//           'Are you sure you want to unassign this branch?',
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(color: Colors.white70),
//             ),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: Text(
//               'Unassign',
//               style: TextStyle(color: AppColors.primaryRed),
//             ),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true && mounted) {
//       try {
//         await context.read<ProviderAdminUsers>().unassignBranchFromInspector(
//           branchId,
//           widget.inspector.id,
//         );
//         await _loadInspectorDetails();
//         if (mounted) {
//           showSnakBarr(context, 'Branch unassigned successfully');
//         }
//       } catch (e) {
//         if (mounted) {
//           showSnakBarr(context, 'Error: $e');
//         }
//       }
//     }
//   }

//   Future<void> _unassignVehicle(String vehicleId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: AppColors.lightBlack,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text(
//           'Unassign Vehicle',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: const Text(
//           'Are you sure you want to unassign this vehicle?',
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(color: Colors.white70),
//             ),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: Text(
//               'Unassign',
//               style: TextStyle(color: AppColors.primaryRed),
//             ),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true && mounted) {
//       try {
//         await context.read<ProviderAdminUsers>().unassignVehicleFromInspector(
//           vehicleId,
//         );
//         await _loadInspectorDetails();
//         if (mounted) {
//           showSnakBarr(context, 'Vehicle unassigned successfully');
//         }
//       } catch (e) {
//         if (mounted) {
//           showSnakBarr(context, 'Error: $e');
//         }
//       }
//     }
//   }
// }
