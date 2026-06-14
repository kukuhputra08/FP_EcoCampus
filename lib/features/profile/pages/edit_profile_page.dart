import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfilePage({
    super.key,
    required this.initialData,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController nameController = TextEditingController();

  static const String cloudinaryCloudName = 'drwstiasl';
  static const String cloudinaryUploadPreset = 'ecocampus_unsigned';

  bool isSaving = false;
  bool isUploadingImage = false;

  String selectedPhotoUrl = '';
  XFile? selectedImageFile;

  @override
  void initState() {
    super.initState();

    nameController.text = getString(widget.initialData, 'name');
    selectedPhotoUrl = getString(widget.initialData, 'photoUrl');
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
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

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        selectedImageFile = image;
      });
    } catch (error) {
      showMessage('Gagal memilih foto: $error');
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih Foto Profile',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ImageSourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Pilih dari Galeri',
                  subtitle: 'Gunakan foto dari perangkat kamu',
                  onTap: () {
                    Navigator.pop(context);
                    pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                _ImageSourceTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Ambil dari Kamera',
                  subtitle: 'Ambil foto profile baru',
                  onTap: () {
                    Navigator.pop(context);
                    pickImage(ImageSource.camera);
                  },
                ),
                if (selectedPhotoUrl.isNotEmpty || selectedImageFile != null)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      _ImageSourceTile(
                        icon: Icons.delete_outline_rounded,
                        title: 'Hapus Foto',
                        subtitle: 'Gunakan avatar huruf depan nama',
                        isDanger: true,
                        onTap: () {
                          Navigator.pop(context);

                          setState(() {
                            selectedPhotoUrl = '';
                            selectedImageFile = null;
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> uploadImageToCloudinary(XFile imageFile) async {
    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
    );

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..fields['folder'] = 'ecocampus/profile'
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

    final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
    final String imageUrl = (jsonResponse['secure_url'] ?? '').toString();

    if (imageUrl.isEmpty) {
      throw Exception('URL foto dari Cloudinary kosong.');
    }

    return imageUrl;
  }

  Future<void> saveProfile() async {
    if (isSaving) return;

    final bool isValid = formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    final User? user = auth.currentUser;

    if (user == null) {
      showMessage('User belum login.');
      return;
    }

    setState(() {
      isSaving = true;
      isUploadingImage = selectedImageFile != null;
    });

    try {
      String finalPhotoUrl = selectedPhotoUrl;

      if (selectedImageFile != null) {
        finalPhotoUrl = await uploadImageToCloudinary(selectedImageFile!);
      }

      final String finalName = nameController.text.trim();

      await firestore.collection('users').doc(user.uid).update({
        'name': finalName,
        'photoUrl': finalPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user.updateDisplayName(finalName);

      if (finalPhotoUrl.isNotEmpty) {
        await user.updatePhotoURL(finalPhotoUrl);
      } else {
        await user.updatePhotoURL(null);
      }

      if (!mounted) return;

      showMessage('Profile berhasil diperbarui.');

      Navigator.pop(context, true);
    } catch (error) {
      showMessage('Gagal menyimpan profile: $error');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
          isUploadingImage = false;
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

  String getInitial() {
    final String name = nameController.text.trim();

    if (name.isEmpty) return 'E';

    return name[0].toUpperCase();
  }

  Widget buildProfileImage() {
    if (selectedImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Image.file(
          File(selectedImageFile!.path),
          fit: BoxFit.cover,
          width: 112,
          height: 112,
        ),
      );
    }

    if (selectedPhotoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Image.network(
          selectedPhotoUrl,
          fit: BoxFit.cover,
          width: 112,
          height: 112,
          errorBuilder: (context, error, stackTrace) {
            return buildInitialAvatar();
          },
        ),
      );
    }

    return buildInitialAvatar();
  }

  Widget buildInitialAvatar() {
    return Center(
      child: Text(
        getInitial(),
        style: const TextStyle(
          color: Color(0xFF0F8A5F),
          fontSize: 44,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String email = getString(
      widget.initialData,
      'email',
      fallback: auth.currentUser?.email ?? '-',
    );

    final String studentId = getString(
      widget.initialData,
      'studentId',
      fallback: '-',
    );

    final String universityName = getString(
      widget.initialData,
      'universityName',
      fallback: '-',
    );

    final String departmentName = getString(
      widget.initialData,
      'departmentName',
      fallback: '-',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      _buildPhotoSection(),
                      const SizedBox(height: 24),
                      _buildFormCard(
                        children: [
                          _ProfileTextField(
                            controller: nameController,
                            label: 'Nama Lengkap',
                            hint: 'Masukkan nama lengkap',
                            icon: Icons.person_outline_rounded,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama tidak boleh kosong.';
                              }

                              if (value.trim().length < 3) {
                                return 'Nama minimal 3 karakter.';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Informasi Akun'),
                      const SizedBox(height: 12),
                      _buildReadOnlyInfoCard(
                        children: [
                          _ReadOnlyInfoItem(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: email,
                          ),
                          _ReadOnlyInfoItem(
                            icon: Icons.badge_outlined,
                            title: 'NRP / NIM',
                            value: studentId,
                          ),
                          _ReadOnlyInfoItem(
                            icon: Icons.school_outlined,
                            title: 'Kampus',
                            value: universityName,
                          ),
                          _ReadOnlyInfoItem(
                            icon: Icons.apartment_rounded,
                            title: 'Jurusan / Departemen',
                            value: departmentName,
                            showDivider: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _buildInfoCard(),
                    ],
                  ),
                ),
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
                  'Edit Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Perbarui nama dan foto profile kamu',
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

  Widget _buildPhotoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9FBE8),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: const Color(0xFF0F8A5F),
                    width: 3,
                  ),
                ),
                child: buildProfileImage(),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: GestureDetector(
                  onTap: isSaving ? null : showImageSourceSheet,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F8A5F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isUploadingImage ? 'Mengupload foto...' : 'Foto Profile',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Gunakan foto yang jelas agar profile kamu mudah dikenali.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: isSaving ? null : showImageSourceSheet,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text(
              'Ubah Foto',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F8A5F),
              side: const BorderSide(
                color: Color(0xFFB7E4C7),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildReadOnlyInfoCard({
    required List<Widget> children,
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
        children: children,
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
              'Email, NRP/NIM, kampus, dan jurusan tidak bisa diubah dari halaman ini agar data akun tetap valid.',
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
            onPressed: isSaving ? null : saveProfile,
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
                    'Simpan Perubahan',
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

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF0F8A5F),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFF0F8A5F),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.6,
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool showDivider;

  const _ReadOnlyInfoItem({
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

class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isDanger
        ? const Color(0xFFEF4444)
        : const Color(0xFF0F8A5F);

    final Color background = isDanger
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFD9FBE8);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
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
                color: background,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDanger
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF111827),
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
            Icon(
              Icons.chevron_right_rounded,
              color: color.withOpacity(0.65),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}