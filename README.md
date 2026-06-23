# 🌿 EcoCampus - Flutter Mobile App

EcoCampus adalah aplikasi mobile berbasis Flutter yang dirancang untuk mendukung keberlanjutan lingkungan di lingkungan kampus. Proyek ini merupakan **Tugas Akhir (Final Project)** untuk mata kuliah **Pengembangan Perangkat Bergerak (PPB)**.

## 🚀 Fitur Utama

Aplikasi ini mencakup berbagai modul fungsional:
- **Authentication**: Registrasi dan login pengguna terintegrasi dengan Firebase.
- **Sustainability Challenges**: Tantangan harian atau mingguan untuk mendorong perilaku ramah lingkungan.
- **Rewards System**: Poin dan penghargaan bagi pengguna yang aktif berkontribusi.
- **Event Management**: Informasi dan pendaftaran kegiatan lingkungan di kampus.
- **Environmental Reporting**: Fitur pelaporan masalah lingkungan di sekitar kampus.
- **User Profile**: Manajemen profil pengguna dan pelacakan progres aktivitas.
- **Onboarding**: Panduan awal bagi pengguna baru saat pertama kali membuka aplikasi.

## 🛠️ Teknologi yang Digunakan

- **Framework**: [Flutter](https://flutter.dev/)
- **Bahasa**: Dart
- **Backend**: [Firebase](https://firebase.google.com/)
    - Firebase Authentication
    - Cloud Firestore (Database)
- **State Management & Tools**:
    - `google_fonts` untuk tipografi.
    - `image_picker` untuk pengambilan gambar pada fitur laporan.
    - `url_launcher` untuk integrasi link eksternal.

## 📦 Instalasi dan Menjalankan Proyek

### Prasyarat
1. Pastikan Flutter SDK sudah terpasang ([Panduan Instalasi](https://docs.flutter.dev/get-started/install)).
2. Memiliki akun Firebase dan proyek Firebase yang aktif.

### Langkah-langkah
1. **Clone repository**:
   ```bash
   git clone <repository-url>
   cd FP-EcoCampus/FP_EcoCampus
   ```

2. **Instal dependensi**:
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Firebase**:
   Pastikan file `lib/firebase_options.dart` sudah terkonfigurasi dengan benar sesuai dengan kredensial Firebase Anda.

4. **Jalankan aplikasi**:
   ```bash
   flutter run
   ```

## 📁 Struktur Proyek
```text
lib/
├── core/             # Utilitas dan konfigurasi inti
├── features/         # Modul fitur (Auth, Home, Events, dll)
├── services/         # Integrasi API dan Firebase
├── main.dart         # Titik masuk aplikasi
└── app.dart          # Konfigurasi root widget
```

