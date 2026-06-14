import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'event_detail_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventData {
  final String id;
  final String title;
  final String description;
  final String location;
  final String status;
  final String scope;
  final String universityName;
  final String departmentName;
  final DateTime? date;
  final int quota;
  final int registeredCount;

  const _EventData({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.scope,
    required this.universityName,
    required this.departmentName,
    required this.date,
    required this.quota,
    required this.registeredCount,
  });
}

class _EventsPageState extends State<EventsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String selectedStatus = 'all';

  final List<Map<String, String>> statusFilters = [
    {
      'value': 'all',
      'label': 'Semua',
    },
    {
      'value': 'active',
      'label': 'Active',
    },
    {
      'value': 'completed',
      'label': 'Completed',
    },
    {
      'value': 'cancelled',
      'label': 'Cancelled',
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

  Stream<QuerySnapshot<Map<String, dynamic>>> getEventsStream({
    required String universityId,
  }) {
    return firestore
        .collection('events')
        .where('universityId', isEqualTo: universityId)
        .snapshots();
  }

  List<_EventData> parseEvents(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final List<_EventData> events = docs.map((doc) {
      final Map<String, dynamic> data = doc.data();

      return _EventData(
        id: doc.id,
        title: (data['title'] ?? 'Event Tanpa Judul').toString(),
        description: (data['description'] ?? '').toString(),
        location: (data['location'] ?? '-').toString(),
        status: (data['status'] ?? '-').toString(),
        scope: (data['scope'] ?? '-').toString(),
        universityName: (data['universityName'] ?? '-').toString(),
        departmentName: (data['createdByDepartmentName'] ??
                data['departmentName'] ??
                '-')
            .toString(),
        date: toDateTime(data['date']),
        quota: toInt(data['quota']),
        registeredCount: toInt(data['registeredCount']),
      );
    }).toList();

    events.sort((a, b) {
      final DateTime dateA =
          a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime dateB =
          b.date ?? DateTime.fromMillisecondsSinceEpoch(0);

      return dateA.compareTo(dateB);
    });

    return events;
  }

  List<_EventData> filterEvents(List<_EventData> events) {
    if (selectedStatus == 'all') {
      return events;
    }

    return events.where((event) {
      final String status = event.status.toLowerCase();

      if (selectedStatus == 'cancelled') {
        return status == 'cancelled' || status == 'canceled';
      }

      return status == selectedStatus;
    }).toList();
  }

  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value.toDate();

    if (value is DateTime) return value;

    if (value is String) return DateTime.tryParse(value);

    return null;
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is String) return int.tryParse(value) ?? 0;

    return 0;
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';

    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final String day = date.day.toString().padLeft(2, '0');
    final String month = months[date.month - 1];
    final String year = date.year.toString();

    return '$day $month $year';
  }

  String statusLabel(String status) {
    final String value = status.toLowerCase();

    if (value == 'active') return 'Active';
    if (value == 'completed') return 'Completed';
    if (value == 'cancelled') return 'Cancelled';
    if (value == 'canceled') return 'Cancelled';
    if (value == 'inactive') return 'Inactive';

    return status.isEmpty ? '-' : status;
  }

  Color statusBackground(String status) {
    final String value = status.toLowerCase();

    if (value == 'active') return const Color(0xFFD9FBE8);
    if (value == 'completed') return const Color(0xFFDFF3FF);
    if (value == 'cancelled' || value == 'canceled') {
      return const Color(0xFFFEE2E2);
    }

    return const Color(0xFFE5E7EB);
  }

  Color statusTextColor(String status) {
    final String value = status.toLowerCase();

    if (value == 'active') return const Color(0xFF166534);
    if (value == 'completed') return const Color(0xFF087EA4);
    if (value == 'cancelled' || value == 'canceled') {
      return const Color(0xFFB91C1C);
    }

    return const Color(0xFF475569);
  }

  void openEventDetail(String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(
          eventId: eventId,
        ),
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

            final String universityName =
                (userData['universityName'] ?? '-').toString();

            final String departmentName =
                (userData['departmentName'] ?? '-').toString();

            if (universityId.isEmpty) {
              return _buildErrorState(
                'Data universitas mahasiswa belum lengkap.',
              );
            }

            return Column(
              children: [
                _buildHeader(
                  context,
                  universityName: universityName,
                  departmentName: departmentName,
                ),
                _buildStatusFilter(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: getEventsStream(
                      universityId: universityId,
                    ),
                    builder: (context, eventSnapshot) {
                      if (eventSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _buildLoadingState();
                      }

                      if (eventSnapshot.hasError) {
                        return _buildErrorState(
                          'Gagal memuat data event.',
                        );
                      }

                      final List<_EventData> allEvents = parseEvents(
                        eventSnapshot.data?.docs ?? [],
                      );

                      final List<_EventData> events =
                          filterEvents(allEvents);

                      if (allEvents.isEmpty) {
                        return _buildEmptyState(
                          title: 'Belum ada event',
                          description:
                              'Event dari admin kampus akan tampil di halaman ini.',
                          icon: Icons.event_busy_rounded,
                        );
                      }

                      if (events.isEmpty) {
                        return _buildEmptyState(
                          title: 'Tidak ada event',
                          description:
                              'Tidak ada event dengan filter yang kamu pilih.',
                          icon: Icons.filter_alt_off_rounded,
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
                        itemCount: events.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: 16);
                        },
                        itemBuilder: (context, index) {
                          final _EventData event = events[index];

                          return _EventCard(
                            event: event,
                            formattedDate: formatDate(event.date),
                            statusLabel: statusLabel(event.status),
                            statusBackground: statusBackground(event.status),
                            statusTextColor: statusTextColor(event.status),
                            onTap: () => openEventDetail(event.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Events Kampus',
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
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w800,
          ),
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

class _EventCard extends StatelessWidget {
  final _EventData event;
  final String formattedDate;
  final String statusLabel;
  final Color statusBackground;
  final Color statusTextColor;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.formattedDate,
    required this.statusLabel,
    required this.statusBackground,
    required this.statusTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int remainingQuota = event.quota - event.registeredCount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
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
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: const Color(0xFFD9FBE8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Color(0xFF0F8A5F),
                size: 33,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 17,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: Color(0xFF94A3B8),
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF94A3B8),
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    event.quota <= 0
                        ? '${event.registeredCount} peserta terdaftar'
                        : '${event.registeredCount}/${event.quota} peserta • Sisa ${remainingQuota < 0 ? 0 : remainingQuota}',
                    style: const TextStyle(
                      color: Color(0xFF0F8A5F),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusTextColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}