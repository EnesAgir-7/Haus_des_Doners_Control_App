import '../core/enums.dart';

class DashboardStats {
  // final int assignedBranches;
  // final int pendingTasks;
  final int inspectionsCount;
  final double averageScore;
  final TimeRange timeRange;

  DashboardStats({
    // required this.assignedBranches,
    // required this.pendingTasks,
    required this.inspectionsCount,
    required this.averageScore,
    required this.timeRange,
  });
}
