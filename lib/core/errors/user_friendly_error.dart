import 'package:firebase_auth/firebase_auth.dart';

String userFriendlyError(Object error) {
  final code = switch (error) {
    FirebaseException firebaseError => firebaseError.code,
    _ => '',
  };
  return switch (code) {
    'permission-denied' => 'Bu işlem için yetkin bulunmuyor.',
    'unavailable' => 'İnternet bağlantısı kurulamadı. Lütfen tekrar dene.',
    'deadline-exceeded' => 'İşlem zaman aşımına uğradı. Lütfen tekrar dene.',
    'not-found' => 'İstenen kayıt bulunamadı.',
    'already-exists' => 'Bu kayıt zaten mevcut.',
    'network-request-failed' => 'İnternet bağlantını kontrol edip tekrar dene.',
    'too-many-requests' => 'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.',
    'requires-recent-login' => 'Güvenlik için yeniden giriş yapman gerekiyor.',
    'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
    _ when error is FirebaseAuthException =>
      'Hesap işlemi tamamlanamadı. Lütfen tekrar dene.',
    _ when error is FirebaseException =>
      'İşlem şu anda tamamlanamadı. Lütfen tekrar dene.',
    _ => error.toString().replaceFirst('Exception: ', ''),
  };
}
