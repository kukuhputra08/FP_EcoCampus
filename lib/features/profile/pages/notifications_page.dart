import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isUpdating = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream(
    String userId,
  ) {
    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  int getCreatedAtMillis(dynamic value) {
    if (value == null) return 0;

    if (value is Timestamp) {
      return value.millisecondsSinceEpoch;
    }

    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }

    return 0;
  }

  String getString(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final dynamic value = data[key];

    if (value == null) return fallback;

    final String text = value.toString().trim();

    if (text.isEmpty) return fallback;

    return text;
  }

  bool getBool(
    Map<String, dynamic> data,
    String key, {
    bool fallback = false,
  }) {
    final dynamic value = data[key];

    if (value == null) return fallback;

    if (value is bool) return value;

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return fallback;
  }

  String formatTime(dynamic value) {
    if (value == null) return 'Baru saja';

    DateTime? dateTime;

    if (value is Timestamp) {
      dateTime = value.toDate();
    } else if (value is DateTime) {
      dateTime = value;
    }

    if (dateTime == null) return 'Baru saja';

    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    }

    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();

    return '$day/$month/$year';
  }

  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'report':
        return Icons.article_outlined;
      case 'challenge':
        return Icons.task_alt_rounded;
      case 'event':
        return Icons.event_available_outlined;
      case 'reward':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color getNotificationColor(String type) {
    switch (type) {
      case 'report':
        return const Color(0xFF087EA4);
      case 'challenge':
        return const Color(0xFF0F8A5F);
      case 'event':
        return const Color(0xFF7C3AED);
      case 'reward':
        return const Color(0xFFB7791F);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color getNotificationBackground(String type) {
    switch (type) {
      case 'report':
        return const Color(0xFFE0F4FF);
      case 'challenge':
        return const Color(0xFFD9FBE8);
      case 'event':
        return const Color(0xFFF3E8FF);
      case 'reward':
        return const Color(0xFFFFF4BA);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      showMessage('Gagal menandai notifikasi: $error');
    }
  }

  Future<void> markAllAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> unreadDocs,
  ) async {
    if (isUpdating || unreadDocs.isEmpty) return;

    setState(() {
      isUpdating = true;
    });

    try {
      final WriteBatch batch = firestore.batch();

      for (final doc in unreadDocs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      showMessage('Semua notifikasi ditandai sudah dibaca.');
    } catch (error) {
      showMessage('Gagal update notifikasi: $error');
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).delete();

      showMessage('Notifikasi berhasil dihapus.');
    } catch (error) {
      showMessage('Gagal menghapus notifikasi: $error');
    }
  }

  void showDeleteDialog(String notificationId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: const Text(
            'Hapus notifikasi?',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Notifikasi ini akan dihapus dari daftar kamu.',
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                deleteNotification(notificationId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Hapus',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = auth.currentUser;

    if (user == null) {
      return _buildNotLoggedInPage();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: getNotificationsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildStreamErrorPage(snapshot.error.toString());
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
            snapshot.data?.docs.toList() ?? [];

        docs.sort((a, b) {
          final int aMillis = getCreatedAtMillis(a.data()['createdAt']);
          final int bMillis = getCreatedAtMillis(b.data()['createdAt']);

          return bMillis.compareTo(aMillis);
        });

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> unreadDocs =
            docs.where((doc) {
          final Map<String, dynamic> data = doc.data();
          return getBool(data, 'isRead') == false;
        }).toList();

        final bool isWaiting =
            snapshot.connectionState == ConnectionState.waiting;

        return Scaffold(
          backgroundColor: const Color(0xFFF7FBF8),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(
                  unreadCount: unreadDocs.length,
                  onMarkAll: unreadDocs.isEmpty
                      ? null
                      : () => markAllAsRead(unreadDocs),
                ),
                Expanded(
                  child: isWaiting
                      ? _buildLoadingState()
                      : docs.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(22, 22, 22, 110),
                              itemCount: docs.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 12);
                              },
                              itemBuilder: (context, index) {
                                final QueryDocumentSnapshot<
                                    Map<String, dynamic>> doc = docs[index];

                                return _NotificationCard(
                                  data: doc.data(),
                                  notificationId: doc.id,
                                  getString: getString,
                                  getBool: getBool,
                                  formatTime: formatTime,
                                  icon: getNotificationIcon(
                                    getString(
                                      doc.data(),
                                      'type',
                                      fallback: 'general',
                                    ),
                                  ),
                                  color: getNotificationColor(
                                    getString(
                                      doc.data(),
                                      'type',
                                      fallback: 'general',
                                    ),
                                  ),
                                  background: getNotificationBackground(
                                    getString(
                                      doc.data(),
                                      'type',
                                      fallback: 'general',
                                    ),
                                  ),
                                  onTap: () {
                                    final bool isRead = getBool(
                                      doc.data(),
                                      'isRead',
                                    );

                                    if (!isRead) {
                                      markAsRead(doc.id);
                                    }
                                  },
                                  onDelete: () {
                                    showDeleteDialog(doc.id);
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotLoggedInPage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              unreadCount: 0,
              onMarkAll: null,
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'User belum login.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamErrorPage(String error) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              unreadCount: 0,
              onMarkAll: null,
            ),
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF14532D).withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Gagal mengambil notifikasi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required int unreadCount,
    required VoidCallback? onMarkAll,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: const BoxDecoration(
        color: Color(0xFF0F8A5F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
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
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  unreadCount == 0
                      ? 'Tidak ada notifikasi baru'
                      : '$unreadCount notifikasi belum dibaca',
                  style: const TextStyle(
                    color: Color(0xFFE5FFF1),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isUpdating ? null : onMarkAll,
            child: Text(
              isUpdating ? '...' : 'Mark all',
              style: TextStyle(
                color: onMarkAll == null
                    ? Colors.white.withOpacity(0.45)
                    : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 34,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14532D).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF0F8A5F),
            ),
            SizedBox(height: 18),
            Text(
              'Mengambil notifikasi...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14532D).withOpacity(0.06),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFD9FBE8),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF0F8A5F),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum ada notifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nanti update laporan, challenge, event, dan reward akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String notificationId;
  final String Function(
    Map<String, dynamic> data,
    String key, {
    String fallback,
  }) getString;
  final bool Function(
    Map<String, dynamic> data,
    String key, {
    bool fallback,
  }) getBool;
  final String Function(dynamic value) formatTime;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.data,
    required this.notificationId,
    required this.getString,
    required this.getBool,
    required this.formatTime,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String title = getString(
      data,
      'title',
      fallback: 'Notifikasi',
    );

    final String message = getString(
      data,
      'message',
      fallback: 'Ada update baru untuk akun kamu.',
    );

    final String type = getString(
      data,
      'type',
      fallback: 'general',
    );

    final bool isRead = getBool(data, 'isRead');
    final String time = formatTime(data['createdAt']);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFEFFDF4),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isRead
                ? const Color(0xFFE5E7EB)
                : const Color(0xFFB7E4C7),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 25,
                  ),
                ),
                if (!isRead)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F8A5F),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFF111827),
                      fontSize: 15.5,
                      fontWeight: isRead ? FontWeight.w800 : FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}