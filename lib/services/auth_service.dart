import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UniversityOption {
  final String id;
  final String name;
  final String shortName;

  const UniversityOption({
    required this.id,
    required this.name,
    required this.shortName,
  });
}

class DepartmentOption {
  final String id;
  final String name;
  final String universityId;

  const DepartmentOption({
    required this.id,
    required this.name,
    required this.universityId,
  });
}

class AcademicOptions {
  final List<UniversityOption> universities;
  final Map<String, List<DepartmentOption>> departmentsByUniversityId;

  const AcademicOptions({
    required this.universities,
    required this.departmentsByUniversityId,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AcademicOptions> getAcademicOptionsFromAdmins() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();

    final Map<String, UniversityOption> universityMap = {};
    final Map<String, Map<String, DepartmentOption>> departmentMap = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final String universityId = (data['universityId'] ?? '').toString();
      final String universityName = (data['universityName'] ?? '').toString();
      final String universityShortName =
          (data['universityShortName'] ?? '').toString();

      final String departmentId = (data['departmentId'] ?? '').toString();
      final String departmentName = (data['departmentName'] ?? '').toString();

      if (universityId.isEmpty ||
          universityName.isEmpty ||
          departmentId.isEmpty ||
          departmentName.isEmpty) {
        continue;
      }

      universityMap[universityId] = UniversityOption(
        id: universityId,
        name: universityName,
        shortName: universityShortName,
      );

      departmentMap.putIfAbsent(universityId, () => {});

      departmentMap[universityId]![departmentId] = DepartmentOption(
        id: departmentId,
        name: departmentName,
        universityId: universityId,
      );
    }

    final List<UniversityOption> universities = universityMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final Map<String, List<DepartmentOption>> departmentsByUniversityId = {};

    for (final entry in departmentMap.entries) {
      final List<DepartmentOption> departments = entry.value.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      departmentsByUniversityId[entry.key] = departments;
    }

    return AcademicOptions(
      universities: universities,
      departmentsByUniversityId: departmentsByUniversityId,
    );
  }

  Future<UserCredential> registerStudent({
    required String name,
    required String email,
    required String studentId,
    required String universityId,
    required String universityName,
    required String universityShortName,
    required String departmentId,
    required String departmentName,
    required String password,
  }) async {
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final User? user = credential.user;

    if (user == null) {
      throw Exception('Gagal membuat akun.');
    }

    await user.updateDisplayName(name.trim());

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': email.trim(),
      'emailVerified': user.emailVerified,
      'studentId': studentId.trim(),
      'role': 'student',
      'universityId': universityId,
      'universityName': universityName,
      'universityShortName': universityShortName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'points': 0,
      'level': 'Eco Starter',
      'photoUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await user.sendEmailVerification();

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    final User? user = _auth.currentUser;

    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> resetPassword({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }
}