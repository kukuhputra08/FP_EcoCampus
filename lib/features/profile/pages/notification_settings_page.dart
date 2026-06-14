import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  bool reportUpdates = true;
  bool challengeUpdates = true;
  bool eventUpdates = true;
  bool rewardUpdates = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final User? user = auth.currentUser;

      if (user == null) {
        throw Exception('User belum login.');
      }

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await firestore.collection('users').doc(user.uid).get();

      if (!snapshot.exists) {
        throw Exception('Data user tidak ditemukan.');
      }

      final Map<String, dynamic> data = snapshot.data() ?? {};
      final dynamic rawSettings = data['notificationSettings'];

      Map<String, dynamic> settings = {};

      if (rawSettings is Map) {
        settings = Map<String, dynamic>.from(rawSettings);
      }

      if (!mounted) return;

      setState(() {
        reportUpdates = getBool(settings, 'reportUpdates', true);
        challengeUpdates = getBool(settings, 'challengeUpdates', true);
        eventUpdates = getBool(settings, 'eventUpdates', true);
        rewardUpdates = getBool(settings, 'rewardUpdates', true);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  bool getBool(
    Map<String, dynamic> data,
    String key,
    bool fallback,
  ) {
    final dynamic value = data[key];

    if (value == null) return fallback;

    if (value is bool) return value;

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return fallback;
  }

  Future<void> saveSettings() async {
    if (isSaving) return;

    final User? user = auth.currentUser;

    if (user == null) {
      showMessage('User belum login.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await firestore.collection('users').doc(user.uid).set(
        {
          'notificationSettings': {
            'reportUpdates': reportUpdates,
            'challengeUpdates': challengeUpdates,
            'eventUpdates': eventUpdates,
            'rewardUpdates': rewardUpdates,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      showMessage('Notification settings berhasil disimpan.');
      Navigator.pop(context, true);
    } catch (error) {
      showMessage('Gagal menyimpan settings: $error');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
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
    if (isLoading) {
      return _buildLoadingPage();
    }

    if (errorMessage != null) {
      return _buildErrorPage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Jenis Notifikasi',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsCard(),
                    const SizedBox(height: 22),
                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildLoadingPage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
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
                        'Mengambil notification settings...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
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

  Widget _buildErrorPage() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                        'Gagal mengambil settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage ?? 'Terjadi kesalahan.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: loadSettings,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(
                            'Coba Lagi',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F8A5F),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
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

  Widget _buildHeader() {
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
            onTap: isSaving ? null : () => Navigator.pop(context),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Atur notifikasi yang ingin kamu terima',
                  style: TextStyle(
                    color: Color(0xFFE5FFF1),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F8A5F),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F8A5F).withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Nanti pengaturan ini dipakai untuk menentukan apakah kamu menerima notifikasi saat laporan, challenge, event, atau reward berubah.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          _NotificationSwitchItem(
            icon: Icons.article_outlined,
            title: 'Report Updates',
            subtitle: 'Saat status laporan kamu berubah',
            value: reportUpdates,
            onChanged: (value) {
              setState(() {
                reportUpdates = value;
              });
            },
          ),
          _NotificationSwitchItem(
            icon: Icons.task_alt_rounded,
            title: 'Challenge Updates',
            subtitle: 'Saat submission challenge di-approve/reject',
            value: challengeUpdates,
            onChanged: (value) {
              setState(() {
                challengeUpdates = value;
              });
            },
          ),
          _NotificationSwitchItem(
            icon: Icons.event_available_outlined,
            title: 'Event Updates',
            subtitle: 'Saat ada event baru atau perubahan event',
            value: eventUpdates,
            onChanged: (value) {
              setState(() {
                eventUpdates = value;
              });
            },
          ),
          _NotificationSwitchItem(
            icon: Icons.card_giftcard_rounded,
            title: 'Reward Updates',
            subtitle: 'Saat reward berhasil ditukar atau diklaim',
            value: rewardUpdates,
            showDivider: false,
            onChanged: (value) {
              setState(() {
                rewardUpdates = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFDF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFB7E4C7),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF0F8A5F),
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Untuk tahap ini, settings hanya disimpan dulu. Setelah itu kita buat sistem in-app notification agar perubahan dari admin bisa muncul di aplikasi.',
              style: TextStyle(
                color: Color(0xFF166534),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isSaving ? null : saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F8A5F),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF94A3B8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: isSaving
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Menyimpan...',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Simpan Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _NotificationSwitchItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _NotificationSwitchItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: value
                      ? const Color(0xFFD9FBE8)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  icon,
                  color: value
                      ? const Color(0xFF0F8A5F)
                      : const Color(0xFF94A3B8),
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch.adaptive(
                value: value,
                activeColor: const Color(0xFF0F8A5F),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF1F5F9),
          ),
      ],
    );
  }
}