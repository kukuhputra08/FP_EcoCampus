import '../models/report_model.dart';

class ReportData {
  static List<ReportModel> reports = [
    ReportModel(
      id: '1',
      title: 'Tumpukan sampah di Gedung B',
      category: 'Sampah',
      location: 'Room 1',
      reportedBy: 'Budi',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'Diproses',
    ),
    ReportModel(
      id: '2',
      title: 'Lampu taman mati depan rektorat',
      category: 'Fasilitas',
      location: 'Room 2',
      reportedBy: 'Budi',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Selesai',
    ),
  ];
}
