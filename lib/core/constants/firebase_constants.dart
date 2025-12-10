import '../../models/user_model.dart';

class Collections {
  static const String branches = 'branches';
  static const String inspectionTemplates = 'inspectionTemplates';
  static const String inspections = 'inspections';
  static const String routes = 'routes';
  static const String tasks = 'tasks';
  // Separate collection for branch authentication users
  static const String branchUsers = 'branch_users';
  static const String vehicles = 'vehicles';
  static const String inspectors = 'inspectors';
  static const String admins = 'admins';
  static const String inspectorStats = 'inspector_history';
  static const String trainingVideos = 'training_videos';
  static const String documents = 'documents';
  static const String documentsSubCollection = 'documents';
  static const String notifications = 'notifications';
  static const String updateRequests = 'update_requests';
}

class VehicleFields {
  static const String plate = 'plate';
  static const String model = 'model';
  static const String assignedInspector = 'assignedInspector';
  static const String assignedInspectorId = 'assignedInspector.id';
  static const String assignedInspectorName = 'assignedInspector.name';
  static const String currentKm = 'currentKm';
  static const String remainingPercent = 'remainingPercent';
  static const String maxKm = 'maxKm';
  static const String remainingKm = 'remainingKm';
  static const String lastServiceDate = 'lastServiceDate';
  static const String nextServiceDue = 'nextServiceDue';
  static const String status = 'status';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

class BranchFields {
  static const String id = 'id';
  static const String name = 'name';
  static const String address = 'address';
  static const String region = 'region';
  static const String gps = 'gps';
  static const String contactName = 'contactName';
  static const String contactPhone = 'contactPhone';
  static const String templateId = 'templateId';
  static const String templateName = 'templateName';
  static const String assignedInspector = 'assignedInspector';
  static const String assignedInspectorId = 'assignedInspector.id';
  static const String assignedInspectorName = 'assignedInspector.name';
  static const String lastInspectionDate = 'lastInspectionDate';
  static const String lastInspectionScore = 'lastInspectionScore';
  static const String last12MonthsScores = 'last12MonthsScores';
  static const String totalInspections = 'totalInspections';
  static const String averageScore = 'averageScore';
  static const String averageRating = 'averageRating';
  static const String status = 'status';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String stop = 'stop'; // nested object
  static const String branchEmail = 'branchEmail';
  static const String openingHours = 'openingHours';
  static const String openingDays = 'openingDays';
  static const String openingDay = 'openingDay';
  static const String suppliers = 'suppliers';
  static const String donerPrices = 'donerPrices';
  static const String software = 'software';
  static const String shopInformation = 'shopInformation';
  static const String branchOwners = 'branchOwners';
  static const String branchManagers = 'branchManagers';
  static const String fcmTokens = 'fcmTokens';
  // branchPassword removed — do not store passwords in Firestore
}

class InspectionFields {
  static const String branchId = 'branchId';
  static const String branchName = 'branchName';
  static const String inspectorId = 'inspectorId';
  static const String inspectorName = 'inspectorName';
  static const String scheduledTime = 'scheduledTime';
  static const String completedTime = 'completedTime';
  static const String status = 'status';
  static const String score = 'score';
  static const String categories = 'categories'; // nested map
  static const String pdfReportUrl = 'pdfReportUrl';
  static const String overallNotes = 'overallNotes';
  static const String photos = 'photos';
  static const String notes = 'notes';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

class IHF {
  static const String inspectorId = 'inspectorId';
  static const String year = 'year';
  static const String month = 'month';
  static const String totalInspections = 'totalInspections';
  static const String avgScore = 'avgScore';
  static const String tasksTotal = 'tasksTotal';
  static const String tasksCompleted = 'tasksCompleted';
  static const String recentScores = 'recentScores';
  static const String vehicleIds = 'vehicleIds';
  static const String branchesIds = 'branchesIds';
  static const String lastUpdated = 'lastUpdated';
}

class RouteFields {
  static const String id = 'id';
  static const String date = 'date';
  static const String inspectorId = 'inspectorId';
  static const String inspectorName = 'inspectorName';
  static const String stops = 'stops';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

class RouteStopFields {
  static const String timeSlot = 'timeSlot';
  static const String branchId = 'branchId';
  static const String branchName = 'branchName';
  static const String branchTemplateId = 'branchTemplateId';
  static const String status = 'status';
  static const String order = 'order';
  static const String createdAt = 'createdAt';
  static const String completedAt = 'completedAt';
  static const String expiryDate = 'expiryDate';
  static const String inspectionScore = 'inspectionScore';
  static const String branchAddress = 'branchAddress';
}

class TrainingVideoFields {
  static const id = 'id';
  static const branchId = 'branchId';
  static const name = 'name';
  static const description = 'description';
  static const videoUrl = 'videoUrl';
  static const createdAt = 'createdAt';
}

class TaskFields {
  static const String title = 'title';
  static const String description = 'description';
  static const String assignedInspectorId = 'assignedInspectorId';
  static const String assignedInspectorName = 'assignedInspectorName';
  static const String relatedBranchId = 'relatedBranchId';
  static const String relatedInspectionId = 'relatedInspectionId';
  static const String status = 'status';
  static const String priority = 'priority';
  static const String dueDate = 'dueDate';
  static const String comments = 'comments';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

class TaskCommentFields {
  static const String userId = 'userId';
  static const String id = 'id';
  static const String userName = 'userName';
  static const String text = 'text';
  static const String timestamp = 'timestamp';
  static const String photos = 'photos';
}

class UserFields {
  static const String id = 'id'; // optional for local storage
  static const String name = 'name';
  static const String role = 'role'; // "admin" | "inspector"
  static const String active = 'active';
  static const String region = 'region';
  static const String serviceAccount = 'serviceAccount';
  static const String fcmTokens = 'fcmTokens';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

class InspectorStatsFields {
  static const String inspectorId = 'inspectorId';
  static const String month = 'month';
  static const String year = 'year';
  static const String totalBranches = 'totalBranches';
  static const String totalInspections = 'totalInspections';
  static const String completedInspections = 'completedInspections';
  static const String pendingInspections = 'pendingInspections';
  static const String averageScore = 'averageScore';
  static const String lastUpdated = 'lastUpdated';
}

class InspectionTemplateFields {
  static const String name = 'name';
  static const String categories = 'categories';
}

class InspectionCategoryFields {
  static const String categoryId = 'categoryId';
  static const String title = 'title';
  static const String maxScore = 'maxScore';
}

class InspectorFields {
  static const String id = 'id';
  static const String name = 'name';
}


class BUF {
  static const String branchId = 'branchId';
  static const String branchName = 'branchName';
  static const String requestedBy = 'requestedBy';
  static const String requestedByName = 'requestedByName';
  static const String requestedAt = 'requestedAt';
  static const String status = 'status';
  static const String changes = 'changes';
  static const String adminNote = 'adminNote';
  static const String reviewedAt = 'reviewedAt';
  static const String reviewedBy = 'reviewedBy';
}

class FCFields {
  static const String fieldName = 'fieldName';
  static const String fieldKey = 'fieldKey';
  static const String oldValue = 'oldValue';
  static const String newValue = 'newValue';
  static const String fieldType = 'fieldType';

}

UserModel? loggedInUser;
