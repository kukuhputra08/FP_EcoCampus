import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _BuildingOption {
  final String id;
  final String name;

  const _BuildingOption({
    required this.id,
    required this.name,
  });
}

class _RoomOption {
  final String id;
  final String name;
  final String buildingId;
  final int floor;
  final String type;

  const _RoomOption({
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

class _CreateReportPageState extends State<CreateReportPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Ganti sesuai .env web admin kamu:
  // VITE_CLOUDINARY_CLOUD_NAME
  // VITE_CLOUDINARY_UPLOAD_PRESET

  static const String cloudinaryCloudName = 'drwstiasl';
  static const String cloudinaryUploadPreset = 'ecocampus_unsigned';

  bool isLoadingInitialData = true;
  bool isSubmitting = false;

  Map<String, dynamic>? studentData;

  List<_BuildingOption> buildings = [];
  List<_RoomOption> rooms = [];

  String? selectedCategory;
  String? selectedBuildingId;
  String? selectedRoomId;

  XFile? selectedImageFile;

  final List<String> categories = [
    'AC Rusak',
    'Lampu Mati',
    'Toilet Bermasalah',
    'Kebocoran Air',
    'Kursi/Meja Rusak',
    'Proyektor Bermasalah',
    'Tempat Sampah Penuh',
    'Kebersihan',
    'Lainnya',
  ];

  String get studentName {
    return (studentData?['name'] ?? auth.currentUser?.displayName ?? 'Mahasiswa')
        .toString();
  }

  String get studentEmail {
    return (studentData?['email'] ?? auth.currentUser?.email ?? '').toString();
  }

  String get studentId {
    return (studentData?['studentId'] ?? '').toString();
  }

  String get universityId {
    return (studentData?['universityId'] ?? '').toString();
  }

  String get universityName {
    return (studentData?['universityName'] ?? '-').toString();
  }

  String get universityShortName {
    return (studentData?['universityShortName'] ?? '').toString();
  }

  String get departmentId {
    return (studentData?['departmentId'] ?? '').toString();
  }

  String get departmentName {
    return (studentData?['departmentName'] ?? '-').toString();
  }

  _BuildingOption? get selectedBuilding {
    if (selectedBuildingId == null) return null;

    try {
      return buildings.firstWhere((building) => building.id == selectedBuildingId);
    } catch (_) {
      return null;
    }
  }

  List<_RoomOption> get availableRooms {
    if (selectedBuildingId == null) return [];

    return rooms
        .where((room) => room.buildingId == selectedBuildingId)
        .toList();
  }

  _RoomOption? get selectedRoom {
    if (selectedRoomId == null) return null;

    try {
      return rooms.firstWhere((room) => room.id == selectedRoomId);
    } catch (_) {
      return null;
    }
  }

  bool get isFormValid {
    return titleController.text.trim().isNotEmpty &&
        selectedCategory != null &&
        selectedBuildingId != null &&
        selectedRoomId != null &&
        descriptionController.text.trim().isNotEmpty &&
        selectedImageFile != null;
  }

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    setState(() {
      isLoadingInitialData = true;
    });

    try {
      final User? user = auth.currentUser;

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

      final Map<String, dynamic> loadedStudentData =
          studentSnapshot.data() ?? {};

      final String loadedUniversityId =
          (loadedStudentData['universityId'] ?? '').toString();

      final String loadedDepartmentId =
          (loadedStudentData['departmentId'] ?? '').toString();

      if (loadedUniversityId.isEmpty || loadedDepartmentId.isEmpty) {
        showMessage('Data universitas/departemen mahasiswa belum lengkap.');
        return;
      }

      final QuerySnapshot<Map<String, dynamic>> buildingSnapshot =
          await firestore
              .collection('buildings')
              .where('universityId', isEqualTo: loadedUniversityId)
              .where('departmentId', isEqualTo: loadedDepartmentId)
              .get();

      final QuerySnapshot<Map<String, dynamic>> roomSnapshot = await firestore
          .collection('rooms')
          .where('universityId', isEqualTo: loadedUniversityId)
          .where('departmentId', isEqualTo: loadedDepartmentId)
          .get();

      final List<_BuildingOption> loadedBuildings =
          buildingSnapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();

        return _BuildingOption(
          id: doc.id,
          name: (data['name'] ?? 'Gedung Tanpa Nama').toString(),
        );
      }).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      final List<_RoomOption> loadedRooms = roomSnapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();

        return _RoomOption(
          id: doc.id,
          name: (data['name'] ?? 'Ruangan Tanpa Nama').toString(),
          buildingId: (data['buildingId'] ?? '').toString(),
          floor: toInt(data['floor']),
          type: (data['type'] ?? '').toString(),
        );
      }).where((room) {
        return room.buildingId.isNotEmpty;
      }).toList()
        ..sort((a, b) {
          final int floorCompare = a.floor.compareTo(b.floor);
          if (floorCompare != 0) return floorCompare;

          return a.name.compareTo(b.name);
        });

      if (!mounted) return;

      setState(() {
        studentData = loadedStudentData;
        buildings = loadedBuildings;
        rooms = loadedRooms;

        selectedBuildingId = null;
        selectedRoomId = null;

        isLoadingInitialData = false;
      });

      if (loadedBuildings.isEmpty) {
        showMessage(
          'Belum ada data gedung dari admin untuk $departmentName, $universityName.',
        );
      } else if (loadedRooms.isEmpty) {
        showMessage(
          'Belum ada data ruangan dari admin untuk $departmentName, $universityName.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingInitialData = false;
      });

      showMessage('Gagal memuat data dari admin: $error');
    }
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
                  subtitle: 'Gunakan kamera untuk foto bukti terbaru.',
                  onTap: () {
                    Navigator.pop(context);
                    pickImageFromCamera();
                  },
                ),
                const SizedBox(height: 12),
                _ImageSourceTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Pilih dari Galeri',
                  subtitle: 'Ambil foto bukti dari album perangkat.',
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

  Future<String> uploadImageToCloudinary(XFile imageFile) async {
    if (cloudinaryCloudName == 'ISI_CLOUD_NAME_KAMU' ||
        cloudinaryUploadPreset == 'ISI_UPLOAD_PRESET_KAMU') {
      throw Exception(
        'Cloudinary belum dikonfigurasi. Isi cloudinaryCloudName dan cloudinaryUploadPreset.',
      );
    }

    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
    );

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..fields['folder'] = 'ecocampus'
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

  Future<void> submitReport() async {
    if (isLoadingInitialData) {
      showMessage('Data dari admin masih dimuat.');
      return;
    }

    if (buildings.isEmpty) {
      showMessage('Belum ada data gedung dari admin.');
      return;
    }

    if (rooms.isEmpty) {
      showMessage('Belum ada data ruangan dari admin.');
      return;
    }

    if (!isFormValid) {
      showMessage('Lengkapi semua data laporan dan foto bukti.');
      return;
    }

    final User? user = auth.currentUser;

    if (user == null) {
      showMessage('User belum login.');
      return;
    }

    final _BuildingOption? building = selectedBuilding;
    final _RoomOption? room = selectedRoom;

    if (building == null || room == null) {
      showMessage('Data gedung atau ruangan tidak valid.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final String imageUrl = await uploadImageToCloudinary(selectedImageFile!);

      final DocumentReference<Map<String, dynamic>> reportRef =
          firestore.collection('reports').doc();

      await reportRef.set({
        'id': reportRef.id,

        // Format utama yang dipakai web admin.
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': selectedCategory,
        'status': 'pending',

        'buildingId': building.id,
        'roomId': room.id,

        'reportedBy': studentName,
        'imageUrl': imageUrl,

        'adminNote': '',

        'universityId': universityId,
        'universityName': universityName,
        'universityShortName': universityShortName,

        'departmentId': departmentId,
        'departmentName': departmentName,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Field tambahan untuk mobile app, tidak mengganggu web admin.
        'studentUid': user.uid,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'studentId': studentId,
        'buildingName': building.name,
        'roomName': room.name,
        'floor': room.floor,
        'roomType': room.type,
        'location': '${building.name} • ${room.label}',
        'source': 'mobile',
      });

      if (!mounted) return;

      showMessage('Laporan berhasil dikirim ke admin.');

      Navigator.pop(context, true);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      showMessage('Firebase error: ${error.message}');
    } catch (error) {
      if (!mounted) return;

      showMessage('Gagal mengirim laporan: $error');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (isLoadingInitialData)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0F8A5F),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
                  children: [
                    _buildCampusInfoCard(),
                    const SizedBox(height: 18),
                    _buildTitleCard(),
                    const SizedBox(height: 18),
                    _buildCategoryCard(),
                    const SizedBox(height: 18),
                    _buildLocationCard(),
                    const SizedBox(height: 18),
                    _buildDescriptionCard(),
                    const SizedBox(height: 18),
                    _buildImageCard(),
                    const SizedBox(height: 18),
                    _buildInfoCard(),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: isLoadingInitialData ? null : _buildBottomButton(),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buat Laporan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Laporkan fasilitas kampus yang bermasalah.',
                  style: TextStyle(
                    color: Color(0xFFE8FFF3),
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
              Icons.assignment_add,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusInfoCard() {
    final bool hasBuilding = buildings.isNotEmpty;
    final bool hasRoom = rooms.isNotEmpty;
    final bool isReady = hasBuilding && hasRoom;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isReady ? const Color(0xFFD9FBE8) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isReady ? const Color(0xFFBBF7D0) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isReady ? Icons.verified_rounded : Icons.warning_amber_rounded,
            color: isReady ? const Color(0xFF0F8A5F) : const Color(0xFFDC2626),
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isReady
                  ? 'Data lokasi diambil dari admin $departmentName, $universityName.'
                  : 'Data gedung/ruangan untuk $departmentName, $universityName belum lengkap di web admin.',
              style: TextStyle(
                color:
                    isReady ? const Color(0xFF166534) : const Color(0xFFB91C1C),
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

  Widget _buildTitleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(
            icon: Icons.title_rounded,
            title: 'Judul Laporan',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            enabled: !isSubmitting,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Contoh: AC ruang kelas tidak dingin',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13.5,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAF9),
              prefixIcon: const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFF0F8A5F),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              enabledBorder: _inputBorder(),
              focusedBorder: _focusedBorder(),
              disabledBorder: _inputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(
            icon: Icons.category_outlined,
            title: 'Kategori Masalah',
          ),
          const SizedBox(height: 14),
          _buildStringDropdown(
            value: selectedCategory,
            hintText: 'Pilih kategori masalah',
            icon: Icons.report_problem_outlined,
            items: categories,
            onChanged: isSubmitting
                ? null
                : (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(
            icon: Icons.location_on_outlined,
            title: 'Detail Lokasi',
          ),
          const SizedBox(height: 8),
          Text(
            '$universityName • $departmentName',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: selectedBuildingId,
            isExpanded: true,
            decoration: _dropdownDecoration(
              hintText: 'Pilih gedung dari data admin',
              icon: Icons.apartment_rounded,
            ),
            items: buildings.map((building) {
              return DropdownMenuItem<String>(
                value: building.id,
                child: Text(
                  building.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: isSubmitting || buildings.isEmpty
                ? null
                : (value) {
                    setState(() {
                      selectedBuildingId = value;
                      selectedRoomId = null;
                    });
                  },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: selectedRoomId,
            isExpanded: true,
            decoration: _dropdownDecoration(
              hintText: selectedBuildingId == null
                  ? 'Pilih gedung terlebih dahulu'
                  : 'Pilih ruangan dari data admin',
              icon: Icons.meeting_room_outlined,
            ),
            items: availableRooms.map((room) {
              return DropdownMenuItem<String>(
                value: room.id,
                child: Text(
                  room.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged:
                isSubmitting || selectedBuildingId == null || availableRooms.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          selectedRoomId = value;
                        });
                      },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(
            icon: Icons.notes_rounded,
            title: 'Deskripsi Masalah',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: descriptionController,
            enabled: !isSubmitting,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText:
                  'Jelaskan masalah fasilitas dengan detail, misalnya kondisi, lokasi spesifik, dan dampaknya.',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13.5,
                height: 1.4,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAF9),
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: _inputBorder(),
              focusedBorder: _focusedBorder(),
              disabledBorder: _inputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle(
            icon: Icons.image_outlined,
            title: 'Foto Bukti',
          ),
          const SizedBox(height: 14),
          GestureDetector(
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
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Foto dipilih',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
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
              'Laporan akan masuk ke web admin sesuai universitas dan departemen mahasiswa. Status awal laporan adalah Pending.',
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
            onPressed: isSubmitting ? null : submitReport,
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
                        'Kirim Laporan',
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

  Widget _buildCardTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
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
    );
  }

  Widget _buildStringDropdown({
    required String? value,
    required String hintText,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _dropdownDecoration(
        hintText: hintText,
        icon: icon,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _dropdownDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF0F8A5F),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      enabledBorder: _inputBorder(),
      focusedBorder: _focusedBorder(),
      disabledBorder: _inputBorder(),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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