import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isSaving = false;
  bool isSendingVerification = false;
  bool isSendingResetPassword = false;
  bool isRefreshingEmailStatus = false;

  String? errorMessage;

  String name = '-';
  String email = '-';
  String role = '-';
  bool emailVerified = false;

  bool showNameInLeaderboard = true;
  bool showPhotoInLeaderboard = true;
  bool allowEventContact = true;

  @override
  void initState() {
    super.initState();
    loadPrivacySecurityData();
  }

  Future<void> loadPrivacySecurityData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final User? user = auth.currentUser;

      if (user == null) {
        throw Exception('User belum login.');
      }

      await user.reload();
      final User? refreshedUser = auth.currentUser;

      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await firestore.collection('users').doc(user.uid).get();

      if (!userSnapshot.exists) {
        throw Exception('Data user tidak ditemukan.');
      }

      final Map<String, dynamic> data = userSnapshot.data() ?? {};
      final dynamic rawPrivacySettings = data['privacySettings'];

      Map<String, dynamic> privacySettings = {};

      if (rawPrivacySettings is Map) {
        privacySettings = Map<String, dynamic>.from(rawPrivacySettings);
      }

      if (!mounted) return;

      setState(() {
        name = getString(data, 'name', fallback: refreshedUser?.displayName ?? '-');
        email = getString(data, 'email', fallback: refreshedUser?.email ?? '-');
        role = getString(data, 'role', fallback: '-');
        emailVerified = refreshedUser?.emailVerified ?? false;

        showNameInLeaderboard = getBool(
          privacySettings,
          'showNameInLeaderboard',
          true,
        );
        showPhotoInLeaderboard = getBool(
          privacySettings,
          'showPhotoInLeaderboard',
          true,
        );
        allowEventContact = getBool(
          privacySettings,
          'allowEventContact',
          true,
        );

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

  String getString(
    Map<String, dynamic> data,
    String key, {
    String fallback = '-',
  }) {
    final dynamic value = data[key];

    if (value == null) return fallback;

    final String text = value.toString().trim();

    if (text.isEmpty) return fallback;

    return text;
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

  String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';

    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();

    return '$day/$month/$year';
  }

  Future<void> refreshEmailVerificationStatus() async {
    if (isRefreshingEmailStatus) return;

    setState(() {
      isRefreshingEmailStatus = true;
    });

    try {
      final User? user = auth.currentUser;

      if (user == null) {
        showMessage('User belum login.');
        return;
      }

      await user.reload();

      final User? refreshedUser = auth.currentUser;

      if (!mounted) return;

      setState(() {
        emailVerified = refreshedUser?.emailVerified ?? false;
      });

      if (emailVerified) {
        showMessage('Email kamu sudah terverifikasi.');
      } else {
        showMessage('Email belum terverifikasi.');
      }
    } catch (error) {
      showMessage('Gagal refresh status email: $error');
    } finally {
      if (mounted) {
        setState(() {
          isRefreshingEmailStatus = false;
        });
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    if (isSendingVerification) return;

    setState(() {
      isSendingVerification = true;
    });

    try {
      final User? user = auth.currentUser;

      if (user == null) {
        showMessage('User belum login.');
        return;
      }

      await user.reload();

      final User? refreshedUser = auth.currentUser;

      if (refreshedUser == null) {
        showMessage('User belum login.');
        return;
      }

      if (refreshedUser.emailVerified) {
        setState(() {
          emailVerified = true;
        });

        showMessage('Email kamu sudah terverifikasi.');
        return;
      }

      await refreshedUser.sendEmailVerification();

      showMessage('Email verifikasi berhasil dikirim ulang.');
    } catch (error) {
      showMessage('Gagal mengirim email verifikasi: $error');
    } finally {
      if (mounted) {
        setState(() {
          isSendingVerification = false;
        });
      }
    }
  }

  Future<void> sendResetPasswordEmail() async {
    if (isSendingResetPassword) return;

    final User? user = auth.currentUser;
    final String? userEmail = user?.email;

    if (userEmail == null || userEmail.trim().isEmpty) {
      showMessage('Email user tidak ditemukan.');
      return;
    }

    setState(() {
      isSendingResetPassword = true;
    });

    try {
      await auth.sendPasswordResetEmail(email: userEmail);

      showMessage('Link reset password sudah dikirim ke $userEmail.');
    } catch (error) {
      showMessage('Gagal mengirim reset password: $error');
    } finally {
      if (mounted) {
        setState(() {
          isSendingResetPassword = false;
        });
      }
    }
  }

  Future<void> savePrivacySettings() async {
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
          'privacySettings': {
            'showNameInLeaderboard': showNameInLeaderboard,
            'showPhotoInLeaderboard': showPhotoInLeaderboard,
            'allowEventContact': allowEventContact,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      showMessage('Privacy settings berhasil disimpan.');
      Navigator.pop(context, true);
    } catch (error) {
      showMessage('Gagal menyimpan privacy settings: $error');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: const Text(
            'Reset password?',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Link reset password akan dikirim ke email $email.',
            style: const TextStyle(
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
                sendResetPasswordEmail();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F8A5F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Kirim Link',
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
    if (isLoading) {
      return _buildLoadingPage();
    }

    if (errorMessage != null) {
      return _buildErrorPage();
    }

    final User? user = auth.currentUser;
    final DateTime? createdAt = user?.metadata.creationTime;
    final DateTime? lastSignInAt = user?.metadata.lastSignInTime;

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
                    _buildSecurityStatusCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Account Security'),
                    const SizedBox(height: 12),
                    _buildSecurityActionCard(
                      createdAt: formatDate(createdAt),
                      lastSignInAt: formatDate(lastSignInAt),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Privacy Settings'),
                    const SizedBox(height: 12),
                    _buildPrivacySettingsCard(),
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
                        'Mengambil data security...',
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
                        'Gagal mengambil data',
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
                          onPressed: loadPrivacySecurityData,
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
                  'Privacy & Security',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Kelola keamanan dan privasi akun',
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

  Widget _buildSecurityStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: emailVerified ? const Color(0xFF0F8A5F) : const Color(0xFFB7791F),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (emailVerified
                    ? const Color(0xFF0F8A5F)
                    : const Color(0xFFB7791F))
                .withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              emailVerified
                  ? Icons.verified_user_outlined
                  : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emailVerified ? 'Akun Terverifikasi' : 'Email Belum Verified',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  emailVerified
                      ? 'Email akun kamu sudah aman dan terverifikasi.'
                      : 'Verifikasi email agar akun kamu lebih aman.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 13,
                    height: 1.4,
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

  Widget _buildSecurityActionCard({
    required String createdAt,
    required String lastSignInAt,
  }) {
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
          _SecurityInfoItem(
            icon: Icons.person_outline_rounded,
            title: 'Nama',
            value: name,
          ),
          _SecurityInfoItem(
            icon: Icons.email_outlined,
            title: 'Email',
            value: email,
          ),
          _SecurityInfoItem(
            icon: Icons.badge_outlined,
            title: 'Role',
            value: role,
          ),
          _SecurityInfoItem(
            icon: Icons.calendar_month_outlined,
            title: 'Akun Dibuat',
            value: createdAt,
          ),
          _SecurityInfoItem(
            icon: Icons.login_rounded,
            title: 'Login Terakhir',
            value: lastSignInAt,
          ),
          _SecurityActionItem(
            icon: Icons.refresh_rounded,
            title: 'Refresh Email Status',
            subtitle: 'Cek ulang apakah email sudah terverifikasi',
            isLoading: isRefreshingEmailStatus,
            onTap: refreshEmailVerificationStatus,
          ),
          if (!emailVerified)
            _SecurityActionItem(
              icon: Icons.mark_email_unread_outlined,
              title: 'Resend Verification Email',
              subtitle: 'Kirim ulang email verifikasi',
              isLoading: isSendingVerification,
              onTap: sendVerificationEmail,
            ),
          _SecurityActionItem(
            icon: Icons.lock_reset_rounded,
            title: 'Reset Password',
            subtitle: 'Kirim link reset password ke email kamu',
            isLoading: isSendingResetPassword,
            showDivider: false,
            onTap: showResetPasswordDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingsCard() {
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
          _PrivacySwitchItem(
            icon: Icons.leaderboard_rounded,
            title: 'Show Name in Leaderboard',
            subtitle: 'Nama kamu bisa muncul di leaderboard',
            value: showNameInLeaderboard,
            onChanged: (value) {
              setState(() {
                showNameInLeaderboard = value;
              });
            },
          ),
          _PrivacySwitchItem(
            icon: Icons.account_circle_outlined,
            title: 'Show Photo in Leaderboard',
            subtitle: 'Foto profile kamu bisa tampil di leaderboard',
            value: showPhotoInLeaderboard,
            onChanged: (value) {
              setState(() {
                showPhotoInLeaderboard = value;
              });
            },
          ),
          _PrivacySwitchItem(
            icon: Icons.event_available_outlined,
            title: 'Allow Event Contact',
            subtitle: 'Panitia/admin bisa menghubungi kamu terkait event',
            value: allowEventContact,
            showDivider: false,
            onChanged: (value) {
              setState(() {
                allowEventContact = value;
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
              'Reset password akan dikirim melalui email. Untuk keamanan, password tidak bisa dilihat atau diubah langsung di aplikasi.',
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
            onPressed: isSaving ? null : savePrivacySettings,
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
                    'Simpan Privacy Settings',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 21,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SecurityInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool showDivider;

  const _SecurityInfoItem({
    required this.icon,
    required this.title,
    required this.value,
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF64748B),
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
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
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

class _SecurityActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;
  final bool showDivider;

  const _SecurityActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: isLoading ? null : onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9FBE8),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF0F8A5F),
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
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Color(0xFF0F8A5F),
                        ),
                      )
                    : const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFCBD5E1),
                        size: 28,
                      ),
              ],
            ),
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

class _PrivacySwitchItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _PrivacySwitchItem({
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