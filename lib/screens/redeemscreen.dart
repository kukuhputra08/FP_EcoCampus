import 'package:flutter/material.dart';

class RewardItem {
  final String id;
  final String title;
  final String description;
  final int cost;
  final String icon;
  final String category;
  final int stock;
  final bool isAvailable;

  const RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.icon,
    required this.category,
    required this.stock,
    required this.isAvailable,
  });
}

class RedeemScreen extends StatefulWidget {
  const RedeemScreen({super.key});

  @override
  State<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends State<RedeemScreen> {
  static const Color _primaryDark = Color(0xFF0D4A30);
  static const Color _primary     = Color(0xFF1A6B4A);
  static const Color _surface     = Color(0xFFF4FAF7);
  static const Color _cardBg      = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0D2B1E);
  static const Color _textSec     = Color(0xFF5A7A6A);

  int _myPoints = 1240;
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua', 'Makanan', 'Merchandise', 'Voucher', 'Donasi'
  ];

  final List<RewardItem> _rewards = const [
    RewardItem(id: 'r1', title: 'Voucher Kantin 10rb',     description: 'Voucher makan di kantin kampus senilai Rp10.000.',           cost: 200,  icon: '🍱', category: 'Makanan',      stock: 50,  isAvailable: true),
    RewardItem(id: 'r2', title: 'Voucher Kantin 25rb',     description: 'Voucher makan di kantin kampus senilai Rp25.000.',           cost: 450,  icon: '🍜', category: 'Makanan',      stock: 30,  isAvailable: true),
    RewardItem(id: 'r3', title: 'Tumbler EcoCampus',       description: 'Tumbler stainless steel eksklusif bertema EcoCampus.',       cost: 500,  icon: '🧴', category: 'Merchandise',  stock: 20,  isAvailable: true),
    RewardItem(id: 'r4', title: 'Tote Bag Eco',            description: 'Tas kanvas ramah lingkungan dengan logo EcoCampus.',         cost: 350,  icon: '👜', category: 'Merchandise',  stock: 15,  isAvailable: true),
    RewardItem(id: 'r5', title: 'Stiker EcoCampus Pack',   description: 'Set 10 stiker eksklusif bertema lingkungan.',                cost: 100,  icon: '🎨', category: 'Merchandise',  stock: 100, isAvailable: true),
    RewardItem(id: 'r6', title: 'Kaos EcoCampus',          description: 'Kaos cotton combed 30s dengan desain eksklusif.',            cost: 800,  icon: '👕', category: 'Merchandise',  stock: 10,  isAvailable: true),
    RewardItem(id: 'r7', title: 'Diskon Fotokopi 20%',     description: 'Voucher diskon fotokopi di koperasi kampus.',                cost: 150,  icon: '🖨️', category: 'Voucher',      stock: 40,  isAvailable: true),
    RewardItem(id: 'r8', title: 'Gratis Parkir 1 Bulan',   description: 'Voucher parkir gratis di area kampus selama 1 bulan.',       cost: 1000, icon: '🅿️', category: 'Voucher',      stock: 5,   isAvailable: true),
    RewardItem(id: 'r9', title: 'Tanam Pohon atas Namamu', description: 'Donasikan 300 pts untuk menanam 1 pohon di kampus.',         cost: 300,  icon: '🌱', category: 'Donasi',       stock: 999, isAvailable: true),
    RewardItem(id: 'r10',title: 'Donasi Bank Sampah',      description: 'Kontribusi 500 pts untuk program daur ulang kampus.',        cost: 500,  icon: '♻️', category: 'Donasi',       stock: 999, isAvailable: true),
    RewardItem(id: 'r11',title: 'Jersey Sepeda Eco',       description: 'Jersey sepeda eksklusif untuk anggota aktif EcoCampus.',     cost: 1500, icon: '🚴', category: 'Merchandise',  stock: 0,   isAvailable: false),
  ];

  // Riwayat redeem dummy
  final List<Map<String, dynamic>> _redeemHistory = [
    {'title': 'Tumbler EcoCampus',     'cost': 500, 'date': '20 Mei 2026', 'status': 'Selesai'},
    {'title': 'Voucher Kantin 10rb',   'cost': 200, 'date': '10 Mei 2026', 'status': 'Selesai'},
    {'title': 'Stiker EcoCampus Pack', 'cost': 100, 'date': '2 Mei 2026',  'status': 'Selesai'},
  ];

  List<RewardItem> get _filtered => _selectedCategory == 'Semua'
      ? _rewards
      : _rewards.where((r) => r.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildPointsBanner()),
          SliverToBoxAdapter(child: _buildCategoryFilter()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (_, i) => _rewardCard(_filtered[i]),
                childCount: _filtered.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8F7F0),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.history_rounded,
                        color: _primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text('Riwayat Redeem',
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) => _historyCard(_redeemHistory[i]),
                childCount: _redeemHistory.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Tukarkan Reward',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildPointsBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D4A30), Color(0xFF2E9E6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Eco Points Kamu',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 12)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$_myPoints',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('pts',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_redeemHistory.length}x',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text('Redeem',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final bool active = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _primary : _cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? _primary : const Color(0xFFE5E7EB)),
              ),
              child: Text(cat,
                  style: TextStyle(
                      color: active ? Colors.white : _textSec,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }

  Widget _rewardCard(RewardItem r) {
    final bool canRedeem = _myPoints >= r.cost && r.isAvailable;
    return GestureDetector(
      onTap: () => _showRedeemDetail(r),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon area
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: canRedeem
                    ? const Color(0xFFE8F7F0)
                    : const Color(0xFFF3F4F6),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(r.icon,
                        style: const TextStyle(fontSize: 40)),
                  ),
                  if (!r.isAvailable)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('Habis',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                  else if (r.stock <= 10)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('Sisa ${r.stock}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFF59E0B), size: 13),
                            const SizedBox(width: 3),
                            Text('${r.cost}',
                                style: const TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: canRedeem
                                ? _primary
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Tukar',
                            style: TextStyle(
                                color: canRedeem
                                    ? Colors.white
                                    : const Color(0xFF9CA3AF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyCard(Map<String, dynamic> h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: const Color(0xFFE8F7F0),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.card_giftcard_rounded,
                color: Color(0xFF2E9E6E), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h['title'],
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(h['date'],
                    style: TextStyle(color: _textSec, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('-${h['cost']} pts',
                  style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F7F0),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(h['status'],
                    style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRedeemDetail(RewardItem r) {
    final bool canRedeem = _myPoints >= r.cost && r.isAvailable;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(r.icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(r.title,
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F0),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(r.category,
                  style: const TextStyle(
                      color: Color(0xFF2E9E6E),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 14),
            Text(r.description,
                style: TextStyle(
                    color: _textSec, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            // Cost info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoCol('Harga', '${r.cost} pts',
                      const Color(0xFFF59E0B)),
                  Container(width: 1, height: 32,
                      color: const Color(0xFFE5E7EB)),
                  _infoCol('Poin Kamu', '$_myPoints pts', _primary),
                  Container(width: 1, height: 32,
                      color: const Color(0xFFE5E7EB)),
                  _infoCol('Sisa', '${r.stock} item',
                      const Color(0xFF3B82F6)),
                ],
              ),
            ),
            if (!canRedeem && r.isAvailable) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Kamu butuh ${r.cost - _myPoints} pts lagi',
                      style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canRedeem ? () => _confirmRedeem(r) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  canRedeem ? _primary : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  canRedeem
                      ? 'Tukarkan Sekarang'
                      : r.isAvailable
                      ? 'Poin Tidak Cukup'
                      : 'Stok Habis',
                  style: TextStyle(
                      color: canRedeem ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _infoCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style:
            TextStyle(color: _textSec, fontSize: 10)),
      ],
    );
  }

  void _confirmRedeem(RewardItem r) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Tukar',
            style:
            TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(
            'Tukarkan "${r.title}" seharga ${r.cost} pts?\n\nSisa poin: ${_myPoints - r.cost} pts',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: TextStyle(color: _textSec)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _myPoints -= r.cost;
                _redeemHistory.insert(0, {
                  'title': r.title,
                  'cost': r.cost,
                  'date': 'Baru saja',
                  'status': 'Diproses',
                });
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 Berhasil menukar "${r.title}"!'),
                  backgroundColor: _primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Tukarkan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}