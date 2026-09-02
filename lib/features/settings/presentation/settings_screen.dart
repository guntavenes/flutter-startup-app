import 'package:ceyizim_plus/core/config/app_update_service.dart';
import 'package:ceyizim_plus/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  late final Future<AppUpdateInfo> _updateInfo = AppUpdateService.check();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar ve Hakkında')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            Icons.auto_stories_outlined,
            'Tanıtımı yeniden göster',
            'Uygulamanın temel özelliklerini tekrar incele',
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OnboardingScreen(
                    onCompleted: () async => Navigator.of(context).pop(),
                  ),
                ),
              );
            },
          ),
          _tile(
            Icons.new_releases_outlined,
            'Yenilikler',
            'Bu sürümde eklenenleri gör',
            _showWhatsNew,
          ),
          _tile(
            Icons.star_outline_rounded,
            'Uygulamayı değerlendir',
            'Mağazada puan vererek destek ol',
            _requestReview,
          ),
          _tile(
            Icons.feedback_outlined,
            'Geri bildirim gönder',
            'Öneri veya sorununu bize ilet',
            _sendFeedback,
          ),
          const SizedBox(height: 20),
          FutureBuilder<PackageInfo>(
            future: _packageInfo,
            builder: (_, snapshot) => Center(
              child: Text(
                snapshot.hasData
                    ? 'Çeyizim+ ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                    : 'Çeyizim+',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );

  Future<void> _showWhatsNew() async {
    final info = await _updateInfo;
    if (!mounted) return;
    final text = info.whatsNew.trim().isNotEmpty
        ? info.whatsNew
        : '• PDF ilerleme ve harcama raporu\n• Akıllı liste ve bütçe önerileri\n• Daha güvenli ortak liste senkronizasyonu\n• Yeni kullanıcı tanıtımı ve bütçe ekranı';
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bu sürümde yenilikler'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mağaza değerlendirmesi şu anda kullanılamıyor.'),
        ),
      );
    }
  }

  Future<void> _sendFeedback() async {
    final package = await _packageInfo;
    final uri = Uri(
      scheme: 'mailto',
      path: 'guntav.enes@gmail.com',
      queryParameters: {
        'subject': 'Çeyizim+ geri bildirim',
        'body': '\n\nSürüm: ${package.version} (${package.buildNumber})',
      },
    );
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-posta uygulaması açılamadı.')),
      );
    }
  }
}
