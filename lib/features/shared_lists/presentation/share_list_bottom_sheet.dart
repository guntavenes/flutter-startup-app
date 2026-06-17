import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_list_providers.dart';

class ShareListBottomSheet extends ConsumerStatefulWidget {
  const ShareListBottomSheet({super.key});

  @override
  ConsumerState<ShareListBottomSheet> createState() =>
      _ShareListBottomSheetState();
}

class _ShareListBottomSheetState extends ConsumerState<ShareListBottomSheet> {
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Davet kodu kopyalandı.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _joinList() async {
    FocusManager.instance.primaryFocus?.unfocus();

    await Future.delayed(const Duration(milliseconds: 120));

    final code = _inviteCodeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Davet kodu girmelisin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      await ref.read(sharedListRepositoryProvider).joinListWithInviteCode(code);

      ref.invalidate(inviteCodeProvider);
      ref.invalidate(activeListIdProvider);

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listeye katıldın.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inviteCodeAsync = ref.watch(inviteCodeProvider);

    return Container(
      margin: const EdgeInsets.all(14),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D3DD),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Icon(
                Icons.group_add_rounded,
                color: Color(0xFFD96BA7),
                size: 38,
              ),
              const SizedBox(height: 10),
              const Text(
                'Listeyi Paylaş',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2C1E26),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Davet kodunu paylaş veya gelen kodla ortak listeye katıl.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9A7A89),
                ),
              ),
              const SizedBox(height: 20),

              inviteCodeAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Text(
                  'Davet kodu alınamadı: $error',
                  textAlign: TextAlign.center,
                ),
                data: (code) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5FA),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFFD6EA)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Davet Kodun',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8A6B79),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          code ?? '-',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: Color(0xFF2C1E26),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: code == null
                                ? null
                                : () => _copyInviteCode(code),
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Kodu Kopyala'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD96BA7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),

              TextField(
                controller: _inviteCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Davet kodu gir',
                  hintText: 'Örn: WV79DD',
                  prefixIcon: const Icon(Icons.key_rounded),
                  filled: true,
                  fillColor: const Color(0xFFFFF8FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isJoining ? null : _joinList,
                  icon: _isJoining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(_isJoining ? 'Katılınıyor...' : 'Listeye Katıl'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD96BA7),
                    side: const BorderSide(color: Color(0xFFD96BA7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
