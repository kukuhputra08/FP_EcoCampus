import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;

  const EventDetailPage({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isRegistering = false;

  User? get currentUser => auth.currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getEventStream() {
    return firestore.collection('events').doc(widget.eventId).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getStudentData() async {
    final User? user = currentUser;

    if (user == null) {
      throw Exception('User belum login.');
    }

    return firestore.collection('users').doc(user.uid).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getParticipantsSnapshot() async {
    return firestore
        .collection('eventParticipants')
        .where('eventId', isEqualTo: widget.eventId)
        .get();
  }

  Future<bool> isAlreadyRegistered({
    required Map<String, dynamic> studentData,
  }) async {
    final User? user = currentUser;

    if (user == null) {
      return false;
    }

    final String studentId = (studentData['studentId'] ?? '').toString();

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await getParticipantsSnapshot();

    return snapshot.docs.any((doc) {
      final Map<String, dynamic> data = doc.data();

      final String participantStudentUid =
          (data['studentUid'] ?? '').toString();

      final String participantStudentId =
          (data['studentId'] ?? '').toString();

      if (participantStudentUid.isNotEmpty) {
        return participantStudentUid == user.uid;
      }

      if (studentId.isNotEmpty) {
        return participantStudentId == studentId;
      }

      return false;
    });
  }

  Future<void> registerAsVolunteer({
    required Map<String, dynamic> eventData,
    required Map<String, dynamic> studentData,
    required int registeredCount,
  }) async {
    final User? user = currentUser;

    if (user == null) {
      showMessage('User belum login.');
      return;
    }

    final String status = (eventData['status'] ?? '').toString().toLowerCase();
    final int quota = toInt(eventData['quota']);

    if (status != 'active') {
      showMessage('Event ini tidak sedang aktif.');
      return;
    }

    if (quota > 0 && registeredCount >= quota) {
      showMessage('Kuota event sudah penuh.');
      return;
    }

    final bool alreadyRegistered = await isAlreadyRegistered(
      studentData: studentData,
    );

    if (alreadyRegistered) {
      showMessage('Kamu sudah terdaftar sebagai volunteer di event ini.');
      return;
    }

    setState(() {
      isRegistering = true;
    });

    try {
      final String studentId = (studentData['studentId'] ?? '').toString();
      final String studentName =
          (studentData['name'] ?? user.displayName ?? 'Mahasiswa').toString();
      final String studentEmail =
          (studentData['email'] ?? user.email ?? '').toString();

      final String departmentId =
          (studentData['departmentId'] ?? '').toString();
      final String departmentName =
          (studentData['departmentName'] ?? '').toString();

      final String universityId =
          (studentData['universityId'] ?? '').toString();
      final String universityName =
          (studentData['universityName'] ?? '').toString();
      final String universityShortName =
          (studentData['universityShortName'] ?? '').toString();

      await firestore.collection('eventParticipants').add({
        'eventId': widget.eventId,

        // Sesuai struktur web admin
        'studentId': studentId,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'departmentId': departmentId,
        'departmentName': departmentName,

        'universityId': universityId,
        'universityName': universityName,
        'universityShortName': universityShortName,

        'registeredAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),

        // Field tambahan untuk mobile, tidak mengganggu web admin
        'studentUid': user.uid,
        'eventTitle': (eventData['title'] ?? '').toString(),
        'source': 'mobile',
      });

      await firestore.collection('events').doc(widget.eventId).update({
        'registeredCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showMessage('Berhasil daftar sebagai volunteer.');
      setState(() {});
    } on FirebaseException catch (error) {
      if (!mounted) return;
      showMessage('Firebase error: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      showMessage('Gagal daftar volunteer: $error');
    } finally {
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
  }

  DateTime? toDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  int toInt(dynamic value) {
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
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');

    if (date.hour == 0 && date.minute == 0) {
      return '$day $month $year';
    }

    return '$day $month $year, $hour:$minute';
  }

  String statusLabel(String status) {
    final String value = status.toLowerCase();

    if (value == 'active') return 'Active';
    if (value == 'inactive') return 'Inactive';
    if (value == 'completed') return 'Completed';
    if (value == 'cancelled') return 'Cancelled';
    if (value == 'canceled') return 'Cancelled';

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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
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
          stream: getEventStream(),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0F8A5F),
                ),
              );
            }

            if (eventSnapshot.hasError) {
              return _buildErrorState('Gagal memuat detail event.');
            }

            if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
              return _buildErrorState('Event tidak ditemukan.');
            }

            final Map<String, dynamic> eventData =
                eventSnapshot.data!.data() ?? {};

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: getStudentData(),
              builder: (context, studentSnapshot) {
                if (studentSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0F8A5F),
                    ),
                  );
                }

                if (studentSnapshot.hasError ||
                    !studentSnapshot.hasData ||
                    !studentSnapshot.data!.exists) {
                  return _buildErrorState('Data mahasiswa tidak ditemukan.');
                }

                final Map<String, dynamic> studentData =
                    studentSnapshot.data!.data() ?? {};

                return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future: getParticipantsSnapshot(),
                  builder: (context, participantSnapshot) {
                    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                        participants = participantSnapshot.data?.docs ?? [];

                    final int participantCount = participants.length;

                    final String studentId =
                        (studentData['studentId'] ?? '').toString();

                    final bool alreadyRegistered = participants.any((doc) {
                      final Map<String, dynamic> participantData = doc.data();

                      final String participantStudentUid =
                          (participantData['studentUid'] ?? '').toString();

                      final String participantStudentId =
                          (participantData['studentId'] ?? '').toString();

                      if (participantStudentUid.isNotEmpty) {
                        return participantStudentUid == user.uid;
                      }

                      if (studentId.isNotEmpty) {
                        return participantStudentId == studentId;
                      }

                      return false;
                    });

                    return _buildEventContent(
                      context: context,
                      eventData: eventData,
                      studentData: studentData,
                      participantCount: participantCount,
                      alreadyRegistered: alreadyRegistered,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventContent({
    required BuildContext context,
    required Map<String, dynamic> eventData,
    required Map<String, dynamic> studentData,
    required int participantCount,
    required bool alreadyRegistered,
  }) {
    final String title = (eventData['title'] ?? 'Event Tanpa Judul').toString();
    final String description =
        (eventData['description'] ?? 'Tidak ada deskripsi.').toString();
    final String location = (eventData['location'] ?? '-').toString();
    final String status = (eventData['status'] ?? '-').toString();
    final String universityName = (eventData['universityName'] ?? '-').toString();
    final String departmentName = (eventData['createdByDepartmentName'] ??
            eventData['departmentName'] ??
            '-')
        .toString();
    final String scope = (eventData['scope'] ?? 'university').toString();

    final DateTime? eventDate = toDateTime(eventData['date']);
    final int quota = toInt(eventData['quota']);
    final int registeredCount =
        participantCount > 0 ? participantCount : toInt(eventData['registeredCount']);

    final int remainingQuota = quota - registeredCount;

    final bool isActive = status.toLowerCase() == 'active';
    final bool isFull = quota > 0 && registeredCount >= quota;

    String buttonText = 'Jadi Volunteer';
    IconData buttonIcon = Icons.volunteer_activism_rounded;
    bool canRegister = true;

    if (!isActive) {
      buttonText = 'Event Tidak Aktif';
      buttonIcon = Icons.block_rounded;
      canRegister = false;
    } else if (alreadyRegistered) {
      buttonText = 'Sudah Terdaftar';
      buttonIcon = Icons.check_circle_rounded;
      canRegister = false;
    } else if (isFull) {
      buttonText = 'Kuota Penuh';
      buttonIcon = Icons.groups_rounded;
      canRegister = false;
    }

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F8A5F),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14532D).withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBadge(
                      label: statusLabel(status),
                      backgroundColor: Colors.white.withOpacity(0.18),
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      universityName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _InfoCard(
                icon: Icons.calendar_month_outlined,
                title: 'Tanggal Event',
                value: formatDate(eventDate),
              ),
              const SizedBox(height: 14),
              _InfoCard(
                icon: Icons.location_on_outlined,
                title: 'Lokasi',
                value: location,
              ),
              const SizedBox(height: 14),
              _InfoCard(
                icon: Icons.groups_rounded,
                title: 'Kuota Volunteer',
                value: quota <= 0
                    ? '$registeredCount volunteer terdaftar'
                    : '$registeredCount / $quota volunteer • Sisa ${remainingQuota < 0 ? 0 : remainingQuota}',
              ),
              const SizedBox(height: 14),
              _InfoCard(
                icon: Icons.account_balance_rounded,
                title: 'Penyelenggara',
                value: '$departmentName • $scope',
              ),
              const SizedBox(height: 24),
              const Text(
                'Deskripsi Event',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: _whiteCardDecoration(),
                child: Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (alreadyRegistered)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9FBE8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF0F8A5F),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kamu sudah terdaftar sebagai volunteer di event ini.',
                          style: TextStyle(
                            color: Color(0xFF166534),
                            fontSize: 13.5,
                            height: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF14532D).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: canRegister && !isRegistering
                    ? () {
                        registerAsVolunteer(
                          eventData: eventData,
                          studentData: studentData,
                          registeredCount: registeredCount,
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F8A5F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: alreadyRegistered
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFF94A3B8),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: isRegistering
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.6,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            buttonIcon,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          const Expanded(
            child: Text(
              'Detail Event',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF14532D).withOpacity(0.05),
          blurRadius: 18,
          offset: const Offset(0, 9),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFD9FBE8),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0F8A5F),
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14.5,
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}