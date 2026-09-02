import 'package:ceyizim_plus/core/config/app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});
  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final info = await AppUpdateService.check();
    if (!mounted || (!info.isRequired && !info.isAvailable)) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: !info.isRequired,
      builder: (dialogContext) => PopScope(
        canPop: !info.isRequired,
        child: AlertDialog(
          title: Text(
            info.isRequired ? 'Güncelleme gerekli' : 'Yeni sürüm hazır',
          ),
          content: Text(
            info.isRequired
                ? 'Çeyizim+ uygulamasını kullanmaya devam etmek için güncellemen gerekiyor.'
                : 'Daha iyi bir deneyim için uygulamanın yeni sürümünü yükleyebilirsin.',
          ),
          actions: [
            if (!info.isRequired)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Daha sonra'),
              ),
            FilledButton(
              onPressed: info.storeUrl.trim().isEmpty
                  ? null
                  : () => launchUrl(
                      Uri.parse(info.storeUrl),
                      mode: LaunchMode.externalApplication,
                    ),
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
