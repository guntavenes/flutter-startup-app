import 'package:ceyizim_plus/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  static const _completedKey = 'onboarding_completed_v1';
  bool? _completed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _completed = preferences.getBool(_completedKey) ?? false);
    }
  }

  Future<void> _complete() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_completedKey, true);
    if (mounted) setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_completed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_completed!) return const HomeScreen();
    return OnboardingScreen(onCompleted: _complete);
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onCompleted});

  final Future<void> Function() onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingData(
      icon: Icons.checklist_rounded,
      title: 'Çeyizini tek yerde planla',
      description:
          'Ürünlerini kategorilere ayır, hedef tarih ve fiyatlarını kolayca takip et.',
      color: Color(0xFFD95F9F),
    ),
    _OnboardingData(
      icon: Icons.people_alt_rounded,
      title: 'Listeyi birlikte yönetin',
      description:
          'Davet kodunu paylaş, partnerinle aynı liste üzerinde güvenle çalış.',
      color: Color(0xFF7B61A8),
    ),
    _OnboardingData(
      icon: Icons.savings_rounded,
      title: 'Bütçeni kontrol altında tut',
      description:
          'Harcanan, planlanan ve kalan bütçeyi anlık olarak görüntüle.',
      color: Color(0xFFE08A24),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onCompleted,
                child: const Text('Atla'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) => _Page(data: _pages[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _page == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _page == index
                        ? const Color(0xFFD95F9F)
                        : const Color(0xFFFFC9DE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (_page == _pages.length - 1) {
                      await widget.onCompleted();
                    } else {
                      await _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(
                    _page == _pages.length - 1 ? 'Başlayalım' : 'Devam',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 72, color: data.color),
          ),
          const SizedBox(height: 42),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF806774),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}
