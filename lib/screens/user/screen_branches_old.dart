// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:haus_des_control/core/constants/firebase_constants.dart';
// import 'package:haus_des_control/models/branch_model.dart';
// import 'package:provider/provider.dart';

// import '../../core/constants/app_assets.dart';
// import '../../core/constants/app_colors.dart';
// import '../../helpers/app_helpers.dart';
// import '../../providers/provider_branches.dart';
// import '../../translations/locale_keys.g.dart';
// import '../../widgets/app_button.dart';
// import '../../widgets/inspector_branch_card.dart';
// import '../common_methods.dart';
// import 'screen_map.dart';

// class BranchesPage extends StatefulWidget {
//   const BranchesPage({super.key});

//   @override
//   State<BranchesPage> createState() => _BranchesPageState();
// }

// class _BranchesPageState extends State<BranchesPage> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<ProviderBranches>().initialize();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         heroTag: "branchesFab",
//         onPressed: () {
//           Navigator.of(context).push(
//             MaterialPageRoute(
//               builder: (context) => BranchMapScreen(
//                 // branches: context.read<ProviderBranches>().branches,
//               ),
//             ),
//           );
//         },
//         child: Icon(Icons.location_on, size: 36),
//       ),
//       body: SafeArea(
//         child: Consumer<ProviderBranches>(
//           builder: (context, provider, child) {
//             return Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.apartment, color: Colors.lightBlueAccent),
//                       SizedBox(width: 6),
//                       Text(
//                         LocaleKeys.my_branches.tr(),
//                         style: TextStyle(
//                           color: AppColors.primaryRed,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       Spacer(),
//                       // Branch count badge
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppColors.lightRed,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           '${LocaleKeys.branch_count.tr().replaceAll(AppConstants.count, provider.branchCount.toString())}',
//                           style: TextStyle(
//                             color: AppColors.primaryRed,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),

//                   // Search bar
//                   TextField(
//                     onChanged: (value) => provider.setSearchQuery(value),
//                     style: TextStyle(color: Colors.white),
//                     decoration: InputDecoration(
//                       hintText: LocaleKeys.search.tr(),
//                       hintStyle: TextStyle(color: Colors.white54),
//                       prefixIcon: Icon(Icons.search, color: Colors.white54),
//                       suffixIcon: provider.searchQuery.isNotEmpty
//                           ? IconButton(
//                               icon: Icon(Icons.clear, color: Colors.white54),
//                               onPressed: () => provider.setSearchQuery(''),
//                             )
//                           : null,
//                       filled: true,
//                       fillColor: AppColors.lightBlack,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.white24),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.white24),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: AppColors.primaryRed),
//                       ),
//                       contentPadding: EdgeInsets.symmetric(vertical: 12),
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   // Sort options
//                   SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       children: [
//                         _buildSortChip(
//                           context,
//                           label: LocaleKeys.sort_by_name.tr(),
//                           value: 'name',
//                           icon: Icons.sort_by_alpha,
//                           provider: provider,
//                         ),
//                         SizedBox(width: 8),
//                         _buildSortChip(
//                           context,
//                           label: LocaleKeys.sort_by_score.tr(),
//                           value: 'score',
//                           icon: Icons.star,
//                           provider: provider,
//                         ),
//                         SizedBox(width: 8),
//                         _buildSortChip(
//                           context,
//                           label: LocaleKeys.sort_by_last_control.tr(),
//                           value: 'lastInspection',
//                           icon: Icons.access_time,
//                           provider: provider,
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 12),
//                   Container(height: 1, color: Colors.white24),
//                   const SizedBox(height: 12),

//                   // Branch list
//                   Expanded(child: _buildBranchList(provider)),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildSortChip(
//     BuildContext context, {
//     required String label,
//     required String value,
//     required IconData icon,
//     required ProviderBranches provider,
//   }) {
//     final isSelected = provider.sortBy == value;
//     return GestureDetector(
//       onTap: () => provider.setSortBy(value),
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? AppColors.primaryRed : AppColors.lightBlack,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isSelected ? AppColors.primaryRed : Colors.white24,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               size: 14,
//               color: isSelected ? Colors.white : Colors.white54,
//             ),
//             SizedBox(width: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 color: isSelected ? Colors.white : Colors.white54,
//                 fontSize: 12,
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBranchList(ProviderBranches provider) {
//     if (provider.isLoading) {
//       return Center(
//         child: CircularProgressIndicator(color: AppColors.primaryRed),
//       );
//     }

//     if (provider.errorMessage != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 60, color: AppColors.primaryRed),
//             SizedBox(height: 16),
//             Text(
//               LocaleKeys.error_occurred.tr(),
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 8),
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 32),
//               child: Text(
//                 provider.errorMessage!,
//                 style: TextStyle(color: Colors.white70),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => provider.refresh(),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primaryRed,
//               ),
//               child: Text(LocaleKeys.try_again.tr()),
//             ),
//           ],
//         ),
//       );
//     }

//     if (provider.branches.isEmpty) {
//       return Center(
//         child: SingleChildScrollView(
//           physics: AlwaysScrollableScrollPhysics(),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.apartment, size: 80, color: Colors.white24),
//               SizedBox(height: 16),
//               Text(
//                 provider.searchQuery.isEmpty
//                     ? LocaleKeys.no_branches_assigned.tr()
//                     : LocaleKeys.branch_not_found.tr(),
//                 style: TextStyle(color: Colors.white70, fontSize: 16),
//               ),
//               if (provider.searchQuery.isNotEmpty) ...[
//                 SizedBox(height: 8),
//                 TextButton(
//                   onPressed: () => provider.setSearchQuery(''),
//                   child: Text(
//                     LocaleKeys.clear_search.tr(),
//                     style: TextStyle(color: AppColors.primaryRed),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: provider.refresh,
//       color: AppColors.primaryRed,
//       backgroundColor: AppColors.lightBlack,
//       child: ListView.builder(
//         physics: AlwaysScrollableScrollPhysics(),
//         itemCount: provider.branches.length,
//         itemBuilder: (context, index) {
//           final branchModel = provider.branches[index];
//           return GestureDetector(
//             onTap: () => _showBranchDetails(context, branchModel, provider),
//             child: InspectorBranchCard(branch: branchModel),
//           );
//         },
//       ),
//     );
//   }

//   void _showBranchDetails(
//     BuildContext context,
//     dynamic branchModel,
//     ProviderBranches provider,
//   ) {
//     provider.selectBranch(branchModel);

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: AppColors.lightBlack,
//       isScrollControlled: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) =>
//           BranchDetailsSheet(branch: branchModel, provider: provider),
//     );
//   }
// }

// // Branch Details Bottom Sheet
// class BranchDetailsSheet extends StatelessWidget {
//   final BranchModel branch;
//   final ProviderBranches provider;

//   BranchDetailsSheet({required this.branch, required this.provider});

//   @override
//   Widget build(BuildContext context) {
//     final isNextInspectionToday =
//         branch.nextInspectionDate != null &&
//         branch.nextInspectionDate!.isNotEmpty &&
//         branch.nextInspectionDate ==
//             DateFormat('yyyy-MM-dd').format(DateTime.now());
//     return DraggableScrollableSheet(
//       initialChildSize: 0.9,
//       minChildSize: 0.5,
//       maxChildSize: 0.95,
//       expand: false,
//       builder: (context, scrollController) {
//         return Padding(
//           padding: EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
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
//               SizedBox(height: 20),
//               Text(
//                 branch.name,
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 8),
//               Row(
//                 children: [
//                   Icon(Icons.location_on, size: 16, color: Colors.white54),
//                   SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       branch.address,
//                       style: TextStyle(color: Colors.white70, fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 12),
//               Row(
//                 children: [
//                   Icon(Icons.person, size: 16, color: Colors.white54),
//                   SizedBox(width: 6),
//                   Text(
//                     '${branch.contactName} - ${branch.contactPhone}',
//                     style: TextStyle(color: Colors.white70, fontSize: 14),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildStatCard(
//                       label: LocaleKeys.average_score.tr(),
//                       value: branch.averageScore.toStringAsFixed(1),
//                       icon: Icons.star,
//                       color: Colors.amber,
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Consumer<ProviderBranches>(
//                       builder: (context, pro, child) {
//                         return _buildStatCard(
//                           label: LocaleKeys.total_inspections.tr(),
//                           value: branch.totalInspections.toString(),
//                           icon: Icons.fact_check,
//                           color: Colors.blue,
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),
//               if (branch.isRouteAssigned && branch.nextInspectionDate != null)
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.green,
//                     borderRadius: BorderRadius.circular(5),

//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.3),
//                         blurRadius: 8,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Row(
//                           children: [
//                             Icon(Icons.next_plan),
//                             SizedBox(width: 8),
//                             Text("Your Next Inspection"),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: EdgeInsets.all(6),
//                         decoration: shadowDeco.copyWith(
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: Text(
//                           isNextInspectionToday
//                               ? "Today"
//                               : formatTimeSlot(
//                                   branch.nextInspectionDate.toString(),
//                                 ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               // SizedBox(height: 16),
//               Divider(color: Colors.white24),
//               SizedBox(height: 12),
//               Text(
//                 "Last 10 Inspections",
//                 style: TextStyle(
//                   color: AppColors.primaryRed,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 12),
//               Expanded(
//                 child: Consumer<ProviderBranches>(
//                   builder: (context, co, _) =>
//                       _buildInspectionHistory(scrollController),
//                 ),
//               ),
//               SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: Consumer<ProviderBranches>(
//                       builder: (context, prod, child) {
//                         return AppButton(
//                           isLoading: prod.isLoading,
//                           text: branch.isRouteAssigned
//                               ? "Remove from Route"
//                               : "Add to Route",
//                           onPressed: () async {
//                             if (branch.isRouteAssigned) {
//                               // Unassign
//                               final success = await prod.unAssignBranchToMe(
//                                 branchId: branch.id,
//                                 context: context,
//                               );

//                               if (success) {
//                                 Navigator.pop(context);
//                               }
//                             } else {
//                               // Show date picker before assigning
//                               final DateTime? pickedDate = await showDatePicker(
//                                 locale: context.locale,
//                                 context: context,
//                                 initialDate: DateTime.now(),
//                                 firstDate: DateTime.now(),
//                                 lastDate: DateTime.now().add(
//                                   const Duration(days: 7),
//                                 ),
//                               );

//                               if (pickedDate != null) {
//                                 final String timeSlot =
//                                     "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";

//                                 final success = await prod.assignBranchToMe(
//                                   branchId: branch.id,
//                                   branchName: branch.name,
//                                   timeSlot: timeSlot,
//                                   context: context,
//                                   branchTemplateId: branch.templateId,
//                                 );

//                                 if (success) {
//                                   Navigator.pop(context);
//                                 }
//                               }
//                             }
//                           },
//                           backgroundColor: branch.isRouteAssigned
//                               ? AppColors.primaryRed
//                               : AppColors.amber,
//                           textStyle: TextStyle(
//                             color: branch.isRouteAssigned
//                                 ? Colors.white
//                                 : AppColors.primaryDark,
//                           ),
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           borderRadius: 10,
//                         );
//                       },
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   Expanded(
//                     child: AppButton(
//                       text: "Back",
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                       backgroundColor: AppColors.primaryRed,
//                       textStyle: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       height: 48,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildStatCard({
//     required String label,
//     required String value,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Container(
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.lightRed,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.white24),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 24),
//           SizedBox(height: 8),
//           Text(
//             value,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(color: Colors.white70, fontSize: 12),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInspectionHistory(ScrollController scrollController) {
//     if (provider.isLoadingInspections) {
//       return Center(
//         child: CircularProgressIndicator(color: AppColors.primaryRed),
//       );
//     }

//     if (provider.branchInspections.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.history, size: 60, color: Colors.white24),
//             SizedBox(height: 12),
//             Text(
//               LocaleKeys.no_inspections_yet.tr(),
//               style: TextStyle(color: Colors.white54),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       controller: scrollController,
//       itemCount: provider.branchInspections.length,
//       itemBuilder: (context, index) {
//         final inspection = provider.branchInspections[index];
//         return Container(
//           margin: EdgeInsets.only(bottom: 12),
//           padding: EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: AppColors.lightRed,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.white24),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Inspected by: ${inspection.inspectorName}",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         formatDate(inspection.updatedAt),
//                         style: TextStyle(
//                           color: AppColors.whiteWithOpacity(.7),
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: _getScoreColor(
//                         inspection.score,
//                       ).withValues(alpha: 0.2),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                         color: _getScoreColor(inspection.score),
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.star,
//                           size: 14,
//                           color: _getScoreColor(inspection.score),
//                         ),
//                         SizedBox(width: 4),
//                         Text(
//                           inspection.score.toStringAsFixed(1),
//                           style: TextStyle(
//                             color: _getScoreColor(inspection.score),
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               if (inspection.overallNotes.isNotEmpty) ...[
//                 SizedBox(height: 8),
//                 Text(
//                   inspection.overallNotes,
//                   style: TextStyle(color: Colors.white70, fontSize: 12),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Color _getScoreColor(double score) {
//     if (score <= 3.0) return Colors.green;
//     if (score <= 7.0) return Colors.amber;
//     return Colors.red;
//   }
// }
