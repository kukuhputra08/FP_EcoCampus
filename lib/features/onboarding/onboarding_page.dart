import 'package:eco_campus/features/welcome_page.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';

class OnboardingItem {
  final String image;
  final String title;
  final String subtitle;

  const OnboardingItem({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  int currentIndex = 0;

  final List<OnboardingItem> items = const [
    OnboardingItem(
      image: AppAssets.splash1,
      title: 'Join the Green Campus Initiative',
      subtitle:
          'Start your sustainability journey by taking small actions that create real impact on campus.',
    ),
    OnboardingItem(
      image: AppAssets.splash2,
      title: 'Collect Points & Redeem Rewards',
      subtitle:
          'Complete eco challenges, earn points, and exchange them for meaningful rewards.',
    ),
    OnboardingItem(
      image: AppAssets.splash3,
      title: 'Report Campus Issues',
      subtitle:
          'Help your campus stay clean and safe by reporting damaged facilities or environmental problems.',
    ),
  ];

  bool get isLastPage => currentIndex == items.length - 1;

  void goNext() {
    if (isLastPage) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WelcomePage(),
        ),
      );
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void skip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomePage(),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FAF5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: skip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF166534),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: items.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(34),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF14532D)
                                      .withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Image.asset(
                                item.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (index) {
                    final isActive = index == currentIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 26 : 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: goNext,
                  child: Text(isLastPage ? 'Get Started' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}