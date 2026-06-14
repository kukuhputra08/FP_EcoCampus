import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ChallengeSubmissionPage extends StatefulWidget {
  final String? challengeId;

  // Legacy params supaya HomePage lama yang memanggil halaman ini tidak error.
  final String? challengeTitle;
  final String? challengeDescription;
  final String? points;
  final IconData? icon;

  const ChallengeSubmissionPage({
    super.key,
    this.challengeId,
    this.challengeTitle,
    this.challengeDescription,
    this.points,
    this.icon,
  });

  @override
  State<ChallengeSubmissionPage> createState() =>
      _ChallengeSubmissionPageState();
}

class _ChallengeSubmissionPageState extends State<ChallengeSubmissionPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  static const String cloudinaryCloudName = 'drwstiasl';
  static const String cloudinaryUploadPreset = 'ecocampus_unsigned';

  bool isLoading = true;
  bool isSubmitting = false;

  Map<String, dynamic>? challengeData;
  Map<String, dynamic>? studentData;

  XFile? selectedImageFile;

  User? get currentUser => auth.currentUser;

  String get challengeTitle {
    return (challengeData?['title'] ??
            widget.challengeTitle ??
            'Challenge Tanpa Judul')
        .toString();
  }

  String get challengeDescription {
    return (challengeData?['description'] ??
            widget.challengeDescription ??
            'Selesaikan challenge ini dan unggah bukti.')
        .toString();
  }

  int get challengePoints {
    final dynamic value = challengeData?['points'] ?? widget.points ?? 0;
    return toInt(value.toString().replaceAll('+', '').replaceAll('pts', ''));
  }

  bool get proofRequired {
    return challengeData?['proofRequired'] == true;
  }

  String get proofType {
    return (challengeData?['proofType'] ?? 'image').toString();
  }

  int get quantityRequired {
    return toInt(challengeData?['quantityRequired']);
  }

  String get studentId {
    return (studentData?['studentId'] ?? '').toString();
  }

  String get studentName {
    return (studentData?['name'] ?? currentUser?.displayName ?? 'Mahasiswa')
        .toString();
  }

  String get studentEmail {
    return (studentData?['email'] ?? currentUser?.email ?? '').toString();
  }

  String get universityId {
    return (studentData?['universityId'] ?? '').toString();
  }

  String get universityName {
    return (studentData?['universityName'] ?? '').toString();
  }

  String get universityShortName {
    return (studentData?['universityShortName'] ?? '').toString();
  }

  String get departmentId {
    return (studentData?['departmentId'] ?? '').toString();
  }

  String get departmentName {
    return (studentData?['departmentName'] ?? '').toString();
  }

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    quantityController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final User? user = currentUser;

      if (user == null) {
        showMessage('User belum login.');
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> studentSnapshot =
          await firestore.collection('users').doc(user.uid).get();

      if (!studentSnapshot.exists) {
        showMessage('Data mahasiswa tidak ditemukan.');
        return;
      }

      Map<String, dynamic>? loadedChallengeData;

      if (widget.challengeId != null && widget.challengeId!.isNotEmpty) {
        final DocumentSnapshot<Map<String, dynamic>> challengeSnapshot =
            await firestore
                .collection('challenges')
                .doc(widget.challengeId)
                .get();

        if (!challengeSnapshot.exists) {
          showMessage('Challenge tidak ditemukan.');
          return;
        }

        loadedChallengeData = challengeSnapshot.data() ?? {};
      }

      if (!mounted) return;

      setState(() {
        studentData = studentSnapshot.data() ?? {};
        challengeData = loadedChallengeData;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage('Gagal memuat data challenge: $error');
    }
  }

  Future<bool> hasSubmittedBefore() async {
    final User? user = currentUser;

    if (user == null || widget.challengeId == null) {
      return false;
    }

    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
        submissionMap = {};

    Future<void> fetchSubmissionsByField(String field, String value) async {
      if (value.trim().isEmpty) return;

      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('challengeSubmissions')
          .where('challengeId', isEqualTo: widget.challengeId)
          .where(field, isEqualTo: value)
          .get();

      for (final doc in snapshot.docs) {
        submissionMap[doc.id] = doc;
      }
    }

    await fetchSubmissionsByField('studentUid', user.uid);
    await fetchSubmissionsByField('studentId', studentId);
    await fetchSubmissionsByField('studentId', user.uid);

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> submissions =
        submissionMap.values.toList();

    if (submissions.isEmpty) {
      return false;
    }

    submissions.sort((a, b) {
      final int aMillis = getSubmissionSortMillis(a.data());
      final int bMillis = getSubmissionSortMillis(b.data());

      return bMillis.compareTo(aMillis);
    });

    final Map<String, dynamic> latestSubmission = submissions.first.data();
    final String latestStatus =
        (latestSubmission['status'] ?? 'submitted').toString();

    return isBlockingSubmissionStatus(latestStatus);
  }

  bool isBlockingSubmissionStatus(String status) {
    final String normalized = status
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    if (normalized == 'rejected' ||
        normalized == 'ejected' ||
        normalized == 'ditolak' ||
        normalized == 'failed' ||
        normalized == 'gagal' ||
        normalized == 'cancelled' ||
        normalized == 'canceled') {
      return false;
    }

    if (normalized == 'submitted' ||
        normalized == 'pending' ||
        normalized == 'menunggu_review' ||
        normalized == 'waiting_review' ||
        normalized == 'in_review' ||
        normalized == 'review' ||
        normalized == 'approved' ||
        normalized == 'accepted' ||
        normalized == 'disetujui') {
      return true;
    }

    return true;
  }

  int getSubmissionSortMillis(Map<String, dynamic> data) {
    final List<String> keys = [
      'submittedAt',
      'createdAt',
      'updatedAt',
      'reviewedAt',
    ];

    int latestMillis = 0;

    for (final String key in keys) {
      final dynamic value = data[key];

      if (value is Timestamp) {
        final int millis = value.millisecondsSinceEpoch;

        if (millis > latestMillis) {
          latestMillis = millis;
        }
      } else if (value is DateTime) {
        final int millis = value.millisecondsSinceEpoch;

        if (millis > latestMillis) {
          latestMillis = millis;
        }
      }
    }

    return latestMillis;
  }

  bool validateForm() {
    if (widget.challengeId == null || widget.challengeId!.isEmpty) {
      showMessage('Challenge dummy tidak bisa disubmit. Buka challenge dari tab Challenge.');
      return false;
    }

    if (proofRequired && selectedImageFile == null) {
      showMessage('Foto bukti wajib diunggah.');
      return false;
    }

    if (quantityRequired > 0) {
      final int submittedQuantity = toInt(quantityController.text.trim());

      if (submittedQuantity <= 0) {
        showMessage('Masukkan jumlah progress challenge.');
        return false;
      }

      if (submittedQuantity < quantityRequired) {
        showMessage('Jumlah belum memenuhi target minimal $quantityRequired.');
        return false;
      }
    }

    return true;
  }

  Future<void> submitChallenge() async {
    if (!validateForm()) {
      return;
    }

    final User? user = currentUser;

    if (user == null) {
      showMessage('User belum login.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final bool alreadySubmitted = await hasSubmittedBefore();

      if (alreadySubmitted) {
        showMessage('Submission kamu masih menunggu review atau sudah disetujui.');
        return;
      }

      String proofImageUrl = '';

      if (selectedImageFile != null) {
        proofImageUrl = await uploadImageToCloudinary(selectedImageFile!);
      }

      final int submittedQuantity = quantityRequired > 0
          ? toInt(quantityController.text.trim())
          : 1;

      await firestore.collection('challengeSubmissions').add({
        'challengeId': widget.challengeId,

        // Data challenge
        'challengeTitle': challengeTitle,
        'pointsAwarded': challengePoints,

        // Data mahasiswa sesuai web admin
        'studentId': studentId,
        'studentName': studentName,
        'studentEmail': studentEmail,

        'departmentId': departmentId,
        'departmentName': departmentName,

        'universityId': universityId,
        'universityName': universityName,
        'universityShortName': universityShortName,

        // Proof
        'proofImageUrl': proofImageUrl,
        'submittedQuantity': submittedQuantity,
        'note': noteController.text.trim(),

        // Status admin
        'status': 'submitted',
        'adminNote': '',

        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': '',

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Tambahan mobile
        'studentUid': user.uid,
        'source': 'mobile',
      });

      if (!mounted) return;

      showMessage('Challenge berhasil disubmit. Menunggu verifikasi admin.');
      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      showMessage('Firebase error: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      showMessage('Gagal submit challenge: $error');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<String> uploadImageToCloudinary(XFile imageFile) async {
    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
    );

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..fields['folder'] = 'ecocampus/challenges'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

    final http.StreamedResponse response = await request.send();
    final String responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal upload foto ke Cloudinary: $responseBody');
    }

    final Map<String, dynamic> data = jsonDecode(responseBody);

    return data['secure_url'].toString();
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1280,
      );

      if (image == null) return;

      setState(() {
        selectedImageFile = image;
      });
    } catch (error) {
      showMessage('Gagal membuka kamera: $error');
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1280,
      );

      if (image == null) return;

      setState(() {
        selectedImageFile = image;
      });
    } catch (error) {
      showMessage('Gagal membuka galeri: $error');
    }
  }

  void showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Pilih Foto Bukti',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                _ImageSourceTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Ambil dari Kamera',
                  subtitle: 'Gunakan kamera untuk bukti challenge.',
                  onTap: () {
                    Navigator.pop(context);
                    pickImageFromCamera();
                  },
                ),
                const SizedBox(height: 12),
                _ImageSourceTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Pilih dari Galeri',
                  subtitle: 'Ambil bukti dari album perangkat.',
                  onTap: () {
                    Navigator.pop(context);
                    pickImageFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static int toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;
    if (value is double) return value.toInt();

    if (value is String) {
      final String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleaned) ?? 0;
    }

    return 0;
  }

  IconData getChallengeIcon() {
    final String value = challengeTitle.toLowerCase();

    if (value.contains('tumbler')) return Icons.local_drink_outlined;
    if (value.contains('foto')) return Icons.camera_alt_rounded;
    if (value.contains('tanam') || value.contains('pohon')) {
      return Icons.park_rounded;
    }
    if (value.contains('bersih')) return Icons.cleaning_services_rounded;

    return widget.icon ?? Icons.emoji_events_rounded;
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
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7FBF8),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0F8A5F),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                children: [
                  _buildChallengeInfoCard(),
                  const SizedBox(height: 18),
                  if (quantityRequired > 0) ...[
                    _buildQuantityCard(),
                    const SizedBox(height: 18),
                  ],
                  _buildProofCard(),
                  const SizedBox(height: 18),
                  _buildNoteCard(),
                  const SizedBox(height: 18),
                  _buildInfoCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildHeader() {
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
            onTap: isSubmitting ? null : () => Navigator.pop(context),
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
              'Submit Challenge',
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

  Widget _buildChallengeInfoCard() {
    return Container(
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
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(
              getChallengeIcon(),
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            challengeTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            challengeDescription,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '+$challengePoints points',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCard() {
    return _FormCard(
      icon: Icons.format_list_numbered_rounded,
      title: 'Jumlah Progress',
      child: TextField(
        controller: quantityController,
        enabled: !isSubmitting,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Target minimal: $quantityRequired',
          filled: true,
          fillColor: const Color(0xFFF8FAF9),
          prefixIcon: const Icon(
            Icons.numbers_rounded,
            color: Color(0xFF0F8A5F),
          ),
          enabledBorder: _inputBorder(),
          focusedBorder: _focusedBorder(),
          disabledBorder: _inputBorder(),
        ),
      ),
    );
  }

  Widget _buildProofCard() {
    return _FormCard(
      icon: Icons.image_outlined,
      title: proofRequired ? 'Foto Bukti Wajib' : 'Foto Bukti',
      child: GestureDetector(
        onTap: isSubmitting ? null : showImageSourceSheet,
        child: Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selectedImageFile == null
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFF86EFAC),
              width: 1.4,
            ),
          ),
          child: selectedImageFile == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFF0F8A5F),
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tambah Foto Bukti',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Ambil dari kamera atau pilih dari galeri',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(selectedImageFile!.path),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedImageFile = null;
                            });
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return _FormCard(
      icon: Icons.notes_rounded,
      title: 'Catatan Tambahan',
      child: TextField(
        controller: noteController,
        enabled: !isSubmitting,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Tambahkan keterangan jika diperlukan.',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13.5,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAF9),
          enabledBorder: _inputBorder(),
          focusedBorder: _focusedBorder(),
          disabledBorder: _inputBorder(),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF0F8A5F),
            size: 23,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Submission akan diverifikasi oleh admin. Points akan diberikan setelah submission disetujui.',
              style: TextStyle(
                color: Color(0xFF166534),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
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
            onPressed: isSubmitting ? null : submitChallenge,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F8A5F),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF94A3B8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.6,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        size: 21,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Submit Challenge',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(
        color: Color(0xFFE2E8F0),
        width: 1.3,
      ),
    );
  }

  OutlineInputBorder _focusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(
        color: Color(0xFF0F8A5F),
        width: 1.5,
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _FormCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF0F8A5F),
                size: 23,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FBF8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
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
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}