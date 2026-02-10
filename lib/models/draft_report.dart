import 'package:hive/hive.dart';

part 'draft_report.g.dart';

/// Hive model for storing draft inspection reports
/// Uses permanent file paths instead of base64 data to avoid size limits
@HiveType(typeId: 0)
class DraftReport extends HiveObject {
  /// Unique identifier - branch ID
  @HiveField(0)
  String branchId;

  /// Template ID for the inspection
  @HiveField(1)
  String branchTemplateId;

  /// Category scores: categoryId -> score
  @HiveField(2)
  Map<String, int> scores;

  /// Category notes: categoryId -> notes text
  @HiveField(3)
  Map<String, String> notes;

  /// Photo file paths: categoryId -> list of permanent file paths
  /// These paths point to files in app documents directory, NOT temp!
  @HiveField(4)
  Map<String, List<String>> photoPaths;

  /// Inspector signature file path (permanent PNG file)
  @HiveField(5)
  String? inspectorSignaturePath;

  /// Branch representative signature file path (permanent PNG file)
  @HiveField(6)
  String? branchSignaturePath;

  /// Overall notes for the inspection
  @HiveField(7)
  String? overallNotes;

  /// Enabled/disabled state for categories: categoryId -> enabled
  @HiveField(8)
  Map<String, bool> enabledCategories;

  /// Timestamp when draft was saved
  @HiveField(9)
  DateTime savedAt;

  /// Branch representative name
  @HiveField(10)
  String? branchRepName;

  DraftReport({
    required this.branchId,
    required this.branchTemplateId,
    required this.scores,
    required this.notes,
    required this.photoPaths,
    this.inspectorSignaturePath,
    this.branchSignaturePath,
    this.overallNotes,
    required this.enabledCategories,
    required this.savedAt,
    this.branchRepName,
  });

  /// Create empty draft
  factory DraftReport.empty(String branchId, String templateId) {
    return DraftReport(
      branchId: branchId,
      branchTemplateId: templateId,
      scores: {},
      notes: {},
      photoPaths: {},
      enabledCategories: {},
      savedAt: DateTime.now(),
    );
  }
}
