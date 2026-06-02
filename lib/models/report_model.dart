class ReportModel {
  final String id;
  final String title;
  final String category;
  final String location;
  final String? imagePath;
  final String reportedBy;
  final DateTime date;
  final String status;

  ReportModel({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    this.imagePath,
    required this.reportedBy,
    required this.date,
    this.status = 'Pending',
  });
}
