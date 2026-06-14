import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _BuildingData {
  final String id;
  final String name;

  const _BuildingData({
    required this.id,
    required this.name,
  });
}

class _RoomData {
  final String id;
  final String name;
  final String buildingId;
  final int floor;
  final String type;

  const _RoomData({
    required this.id,
    required this.name,
    required this.buildingId,
    required this.floor,
    required this.type,
  });

  String get label {
    if (type.trim().isEmpty) {
      return '$name • Lantai $floor';
    }

    return '$name • Lantai $floor • $type';
  }
}

class _ReportData {
  final String id;
  final String title;
  final String category;
  final String description;
  final String status;
  final String buildingId;
  final String roomId;
  final String imageUrl;
  final String adminNote;
  final String reportedBy;
  final String buildingName;
  final String roomName;
  final int floor;
  final String roomType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const _ReportData({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.status,
    required this.buildingId,
    required this.roomId,
    required this.imageUrl,
    required this.adminNote,
    required this.reportedBy,
    required this.buildingName,
    required this.roomName,
    required this.floor,
    required this.roomType,
    required this.createdAt,
    required this.updatedAt,
  });
}

class _ReportsPageState extends State<ReportsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String selectedStatus = 'all';

  final List<Map<String, String>> statusFilters = [
    {
      'value': 'all',
      'label': 'Semua',
    },
    {
      'value': 'pending',
      'label': 'Pending',
    },
    {
      'value': 'in_progress',
      'label': 'Proses',
    },
    {
      'value': 'completed',
      'label': 'Selesai',
    },
    {
      'value': 'rejected',
      'label': 'Ditolak',
    },
  ];

  User? get currentUser => auth.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream() {
    final User? user = currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return firestore.collection('users').doc(user.uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReportsStream() {
    final User? user = currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return firestore
        .collection('reports')
        .where('studentUid', isEqualTo: user.uid)
        .snapshots();
  }

  Future<Map<String, dynamic>> loadLocationData({
    required String universityId,
    required String departmentId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> buildingSnapshot =
        await firestore
            .collection('buildings')
            .where('universityId', isEqualTo: universityId)
            .where('departmentId', isEqualTo: departmentId)
            .get();

    final QuerySnapshot<Map<String, dynamic>> roomSnapshot = await firestore
        .collection('rooms')
        .where('universityId', isEqualTo: universityId)
        .where('departmentId', isEqualTo: departmentId)
        .get();

    final Map<String, _BuildingData> buildingMap = {};

    for (final doc in buildingSnapshot.docs) {
      final data = doc.data();

      buildingMap[doc.id] = _BuildingData(
        id: doc.id,
        name: (data['name'] ?? 'Unknown Building').toString(),
      );
    }

    final Map<String, _RoomData> roomMap = {};

    for (final doc in roomSnapshot.docs) {
      final data = doc.data();

      roomMap[doc.id] = _RoomData(
        id: doc.id,
        name: (data['name'] ?? 'Unknown Room').toString(),
        buildingId: (data['buildingId'] ?? '').toString(),
        floor: toInt(data['floor']),
        type: (data['type'] ?? '').toString(),
      );
    }

    return {
      'buildings': buildingMap,
      'rooms': roomMap,
    };
  }

  List<_ReportData> parseReports(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final List<_ReportData> reports = docs.map((doc) {
      final Map<String, dynamic> data = doc.data();

      return _ReportData(
        id: doc.id,
        title: (data['title'] ?? 'Laporan Tanpa Judul').toString(),
        category: (data['category'] ?? '-').toString(),
        description: (data['description'] ?? '-').toString(),
        status: (data['status'] ?? 'pending').toString(),
        buildingId: (data['buildingId'] ?? '').toString(),
        roomId: (data['roomId'] ?? '').toString(),
        imageUrl: (data['imageUrl'] ?? '').toString(),
        adminNote: (data['adminNote'] ?? '').toString(),
        reportedBy: (data['reportedBy'] ?? data['studentName'] ?? '-')
            .toString(),
        buildingName: (data['buildingName'] ?? '').toString(),
        roomName: (data['roomName'] ?? '').toString(),
        floor: toInt(data['floor']),
        roomType: (data['roomType'] ?? '').toString(),
        createdAt: toDateTime(data['createdAt']),
        updatedAt: toDateTime(data['updatedAt']),
      );
    }).toList();

    reports.sort((a, b) {
      final DateTime dateA =
          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime dateB =
          b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return dateB.compareTo(dateA);
    });

    return reports;
  }

  List<_ReportData> filterReports(List<_ReportData> reports) {
    if (selectedStatus == 'all') {
      return reports;
    }

    return reports.where((report) => report.status == selectedStatus).toList();
  }

  String getBuildingName(
    _ReportData report,
    Map<String, _BuildingData> buildingMap,
  ) {
    if (report.buildingId.isNotEmpty &&
        buildingMap.containsKey(report.buildingId)) {
      return buildingMap[report.buildingId]!.name;
    }

    if (report.buildingName.isNotEmpty) {
      return report.buildingName;
    }

    return 'Unknown Building';
  }

  String getRoomName(
    _ReportData report,
    Map<String, _RoomData> roomMap,
  ) {
    if (report.roomId.isNotEmpty && roomMap.containsKey(report.roomId)) {
      return roomMap[report.roomId]!.label;
    }

    if (report.roomName.isNotEmpty) {
      if (report.floor > 0 && report.roomType.isNotEmpty) {
        return '${report.roomName} • Lantai ${report.floor} • ${report.roomType}';
      }

      if (report.floor > 0) {
        return '${report.roomName} • Lantai ${report.floor}';
      }

      return report.roomName;
    }

    return 'Area umum';
  }

  String getLocationText(
    _ReportData report,
    Map<String, _BuildingData> buildingMap,
    Map<String, _RoomData> roomMap,
  ) {
    final String buildingName = getBuildingName(report, buildingMap);
    final String roomName = getRoomName(report, roomMap);

    return '$buildingName / $roomName';
  }

  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';

    final DateTime now = DateTime.now();

    final bool isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) {
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');

      return 'Hari ini, $hour:$minute';
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day/$month/$year';
  }

  String statusLabel(String status) {
    if (status == 'pending') return 'Pending';
    if (status == 'in_progress') return 'In Progress';
    if (status == 'completed') return 'Completed';
    if (status == 'rejected') return 'Rejected';

    return status;
  }

  Color statusBackgroundColor(String status) {
    if (status == 'pending') return const Color(0xFFFFF7D6);
    if (status == 'in_progress') return const Color(0xFFDFF3FF);
    if (status == 'completed') return const Color(0xFFD9FBE8);
    if (status == 'rejected') return const Color(0xFFFEE2E2);

    return const Color(0xFFE5E7EB);
  }

  Color statusTextColor(String status) {
    if (status == 'pending') return const Color(0xFF715C00);
    if (status == 'in_progress') return const Color(0xFF087EA4);
    if (status == 'completed') return const Color(0xFF166534);
    if (status == 'rejected') return const Color(0xFFB91C1C);

    return const Color(0xFF475569);
  }

  IconData statusIcon(String status) {
    if (status == 'pending') return Icons.schedule_rounded;
    if (status == 'in_progress') return Icons.sync_rounded;
    if (status == 'completed') return Icons.check_circle_rounded;
    if (status == 'rejected') return Icons.cancel_rounded;

    return Icons.info_rounded;
  }

  IconData categoryIcon(String category) {
    final String value = category.toLowerCase();

    if (value.contains('ac')) return Icons.ac_unit_rounded;
    if (value.contains('lampu')) return Icons.lightbulb_outline_rounded;
    if (value.contains('toilet')) return Icons.wc_rounded;
    if (value.contains('air') || value.contains('bocor')) {
      return Icons.water_drop_outlined;
    }
    if (value.contains('kursi') || value.contains('meja')) {
      return Icons.chair_outlined;
    }
    if (value.contains('proyektor')) return Icons.videocam_off_outlined;
    if (value.contains('sampah')) return Icons.delete_outline_rounded;
    if (value.contains('bersih')) return Icons.cleaning_services_outlined;

    return Icons.assignment_rounded;
  }

  void openReportDetail({
    required _ReportData report,
    required String locationText,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: statusBackgroundColor(report.status),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        categoryIcon(report.category),
                        color: statusTextColor(report.status),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 21,
                              height: 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StatusBadge(
                            label: statusLabel(report.status),
                            backgroundColor: statusBackgroundColor(report.status),
                            textColor: statusTextColor(report.status),
                            icon: statusIcon(report.status),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (report.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      report.imageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImageErrorBox();
                      },
                    ),
                  )
                else
                  _buildImageErrorBox(),
                const SizedBox(height: 22),
                _DetailInfoCard(
                  icon: Icons.category_outlined,
                  title: 'Kategori',
                  value: report.category,
                ),
                const SizedBox(height: 12),
                _DetailInfoCard(
                  icon: Icons.location_on_outlined,
                  title: 'Lokasi',
                  value: locationText,
                ),
                const SizedBox(height: 12),
                _DetailInfoCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'Tanggal Laporan',
                  value: formatDate(report.createdAt),
                ),
                const SizedBox(height: 12),
                _DetailInfoCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Dilaporkan Oleh',
                  value: report.reportedBy,
                ),
                const SizedBox(height: 22),
                const Text(
                  'Deskripsi',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  report.description,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Catatan Admin',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    report.adminNote.trim().isEmpty
                        ? 'Belum ada catatan dari admin.'
                        : report.adminNote,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildImageErrorBox() {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Color(0xFF94A3B8),
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'Foto tidak tersedia',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7FBF8),
        body: Center(
          child: Text(
            'User belum login.',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: getUserStream(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (userSnapshot.hasError) {
              return _buildErrorState('Gagal memuat data mahasiswa.');
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return _buildErrorState('Data mahasiswa tidak ditemukan.');
            }

            final Map<String, dynamic> userData =
                userSnapshot.data!.data() ?? {};

            final String universityId =
                (userData['universityId'] ?? '').toString();
            final String departmentId =
                (userData['departmentId'] ?? '').toString();

            final String universityName =
                (userData['universityName'] ?? '-').toString();
            final String departmentName =
                (userData['departmentName'] ?? '-').toString();

            if (universityId.isEmpty || departmentId.isEmpty) {
              return _buildErrorState(
                'Data universitas atau departemen mahasiswa belum lengkap.',
              );
            }

            return FutureBuilder<Map<String, dynamic>>(
              future: loadLocationData(
                universityId: universityId,
                departmentId: departmentId,
              ),
              builder: (context, locationSnapshot) {
                if (locationSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (locationSnapshot.hasError) {
                  return _buildErrorState(
                    'Gagal memuat data lokasi dari admin.',
                  );
                }

                final Map<String, _BuildingData> buildingMap =
                    (locationSnapshot.data?['buildings']
                            as Map<String, _BuildingData>?) ??
                        {};

                final Map<String, _RoomData> roomMap =
                    (locationSnapshot.data?['rooms']
                            as Map<String, _RoomData>?) ??
                        {};

                return Column(
                  children: [
                    _buildHeader(
                      universityName: universityName,
                      departmentName: departmentName,
                    ),
                    _buildStatusFilter(),
                    Expanded(
                      child:
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: getReportsStream(),
                        builder: (context, reportSnapshot) {
                          if (reportSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingState();
                          }

                          if (reportSnapshot.hasError) {
                            return _buildErrorState(
                              'Gagal memuat data laporan.',
                            );
                          }

                          final List<_ReportData> allReports = parseReports(
                            reportSnapshot.data?.docs ?? [],
                          );

                          final List<_ReportData> reports =
                              filterReports(allReports);

                          if (allReports.isEmpty) {
                            return _buildEmptyState(
                              title: 'Belum ada laporan',
                              description:
                                  'Laporan yang kamu buat akan tampil di halaman ini.',
                              icon: Icons.assignment_outlined,
                            );
                          }

                          if (reports.isEmpty) {
                            return _buildEmptyState(
                              title: 'Tidak ada laporan',
                              description:
                                  'Tidak ada laporan dengan status ${statusLabel(selectedStatus)}.',
                              icon: Icons.filter_alt_off_outlined,
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
                            itemCount: reports.length,
                            separatorBuilder: (context, index) {
                              return const SizedBox(height: 16);
                            },
                            itemBuilder: (context, index) {
                              final _ReportData report = reports[index];

                              final String locationText = getLocationText(
                                report,
                                buildingMap,
                                roomMap,
                              );

                              return _ReportCard(
                                report: report,
                                locationText: locationText,
                                formattedDate: formatDate(report.createdAt),
                                statusLabel: statusLabel(report.status),
                                statusBackgroundColor:
                                    statusBackgroundColor(report.status),
                                statusTextColor: statusTextColor(report.status),
                                statusIcon: statusIcon(report.status),
                                categoryIcon: categoryIcon(report.category),
                                onTap: () {
                                  openReportDetail(
                                    report: report,
                                    locationText: locationText,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String universityName,
    required String departmentName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
      decoration: const BoxDecoration(
        color: Color(0xFF0F8A5F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Laporan Saya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$departmentName • $universityName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8FFF3),
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statusFilters.map((item) {
            final bool isSelected = selectedStatus == item['value'];

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedStatus = item['value']!;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0F8A5F)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0F8A5F)
                          : const Color(0xFFE5E7EB),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14532D).withOpacity(0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    item['label']!,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0F8A5F),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFD9FBE8),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0F8A5F),
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final _ReportData report;
  final String locationText;
  final String formattedDate;
  final String statusLabel;
  final Color statusBackgroundColor;
  final Color statusTextColor;
  final IconData statusIcon;
  final IconData categoryIcon;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.locationText,
    required this.formattedDate,
    required this.statusLabel,
    required this.statusBackgroundColor,
    required this.statusTextColor,
    required this.statusIcon,
    required this.categoryIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14532D).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F3),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                categoryIcon,
                color: const Color(0xFF0F8A5F),
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    locationText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _StatusBadge(
              label: statusLabel,
              backgroundColor: statusBackgroundColor,
              textColor: statusTextColor,
              icon: statusIcon,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFD9FBE8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0F8A5F),
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}