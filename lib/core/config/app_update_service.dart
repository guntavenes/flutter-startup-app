import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.isRequired,
    required this.isAvailable,
    required this.storeUrl,
    required this.whatsNew,
  });
  final bool isRequired;
  final bool isAvailable;
  final String storeUrl;
  final String whatsNew;
}

class AppUpdateService {
  const AppUpdateService._();

  static Future<AppUpdateInfo> check() async {
    final config = FirebaseRemoteConfig.instance;
    await config.setDefaults(const {
      'minimum_build_number': 0,
      'latest_build_number': 0,
      'store_url': '',
      'whats_new': '',
    });
    await config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        minimumFetchInterval: const Duration(hours: 6),
      ),
    );
    try {
      await config.fetchAndActivate();
    } catch (_) {
      // Güncelleme kontrolü uygulamanın açılmasını engellememeli.
    }
    final package = await PackageInfo.fromPlatform();
    final build = int.tryParse(package.buildNumber) ?? 0;
    final minimum = config.getInt('minimum_build_number');
    final latest = config.getInt('latest_build_number');
    final storeUrl = config.getString('store_url').trim();
    return AppUpdateInfo(
      isRequired: storeUrl.isNotEmpty && minimum > 0 && build < minimum,
      isAvailable: storeUrl.isNotEmpty && latest > 0 && build < latest,
      storeUrl: storeUrl,
      whatsNew: config.getString('whats_new'),
    );
  }
}
