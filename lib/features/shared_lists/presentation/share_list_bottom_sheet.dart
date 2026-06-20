import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';

import '../../categories/data/category_providers.dart';
import '../data/shared_list_providers.dart';

class ShareListBottomSheet extends ConsumerStatefulWidget {
  final Future<void> Function()? onBeforeLeaveList;
  const ShareListBottomSheet({super.key, this.onBeforeLeaveList});
  @override
  ConsumerState<ShareListBottomSheet> createState() =>
      _ShareListBottomSheetState();
}

class _ShareListBottomSheetState extends ConsumerState<ShareListBottomSheet> {
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _isJoining = false;
  final TextEditingController _displayNameController = TextEditingController();
  bool _isSavingName = false;
  bool _isCurrentListCode = false;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    _displayNameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _displayNameController.dispose();
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

    final code = _inviteCodeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Davet kodu girmelisin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentInviteCode = await ref.read(inviteCodeProvider.future);

    if (code == currentInviteCode) {
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      await ref.read(sharedListRepositoryProvider).joinListWithInviteCode(code);

      ref.invalidate(activeListIdProvider);
      ref.invalidate(inviteCodeProvider);
      ref.invalidate(itemRepositoryProvider);
      ref.invalidate(membersProvider);

      await Future.delayed(const Duration(milliseconds: 200));

      final categoryRepository = ref.read(categoryRepositoryProvider);
      final itemRepository = ref.read(itemRepositoryProvider);

      await categoryRepository.syncCategoriesFromFirestore();

      await itemRepository.mergeLocalItemsToActiveSharedList();
      await itemRepository.syncItemsFromFirestore();

      ref.invalidate(categoriesProvider);

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      navigator.pop(true);

      messenger.showSnackBar(
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

  Future<void> _saveDisplayName() async {
    final name = _displayNameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İsim boş olamaz.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSavingName = true;
    });

    try {
      await ref
          .read(sharedListRepositoryProvider)
          .updateCurrentUserDisplayName(name);

      ref.invalidate(membersProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İsim güncellendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingName = false;
        });
      }
    }
  }

  Future<void> _onInviteCodeChanged(String value) async {
    final code = value.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _isCurrentListCode = false;
      });
      return;
    }

    final currentCode = await ref.read(inviteCodeProvider.future);

    if (!mounted) return;

    setState(() {
      _isCurrentListCode = currentCode == code;
    });
  }

  Future<void> _leaveList() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Listeden ayrıl?'),
          content: const Text(
            'Bu ortak listeden ayrılacaksın. Mevcut ürünlerin telefonunda kalacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ayrıl'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await widget.onBeforeLeaveList?.call();
      await ref.read(sharedListRepositoryProvider).leaveActiveSharedList();

      ref.invalidate(activeListIdProvider);
      ref.invalidate(inviteCodeProvider);
      ref.invalidate(membersProvider);
      ref.invalidate(categoriesProvider);

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listeden ayrıldın.'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final inviteCodeAsync = ref.watch(inviteCodeProvider);

    final membersAsync = ref.watch(membersProvider);

    final currentInviteCode = inviteCodeAsync.value?.trim().toUpperCase();

    final enteredInviteCode = _inviteCodeController.text.trim().toUpperCase();

    final isCurrentListCode =
        currentInviteCode != null &&
        enteredInviteCode.isNotEmpty &&
        enteredInviteCode == currentInviteCode;

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
              Row(
                children: [
                  const Spacer(),

                  const Text(
                    'Listeyi Paylaş',

                    style: TextStyle(
                      fontSize: 22,

                      fontWeight: FontWeight.w900,

                      color: Color(0xFF2C1E26),
                    ),
                  ),

                  const Spacer(),

                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),

                    icon: const Icon(Icons.close_rounded),

                    color: Color(0xFF9A7A89),
                  ),
                ],
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

              membersAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (members) {
                  final isSharedList = members.length > 1;

                  if (!isSharedList) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

                      TextField(
                        controller: _displayNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Görünen ismin',
                          hintText: 'Örn: Enes',
                          prefixIcon: const Icon(Icons.person_rounded),
                          filled: true,
                          fillColor: const Color(0xFFFFF8FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _isSavingName ? null : _saveDisplayName,
                          icon: _isSavingName
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _isSavingName ? 'Kaydediliyor...' : 'İsmi Kaydet',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD96BA7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          const Text(
                            'Liste Üyeleri',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C1E26),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5FA),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${members.length} kişi',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD96BA7),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      ...members.map((member) {
                        final name =
                            member.displayName ?? member.email ?? 'Kullanıcı';
                        final firstLetter = name.isEmpty
                            ? '?'
                            : name.substring(0, 1).toUpperCase();

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFD6EA),
                            child: Text(
                              firstLetter,
                              style: const TextStyle(
                                color: Color(0xFFD96BA7),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2C1E26),
                                  ),
                                ),
                              ),
                              if (member.role == 'owner')
                                const Text(
                                  '👑',
                                  style: TextStyle(fontSize: 18),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            member.role == 'owner'
                                ? 'Liste Sahibi'
                                : 'Ortak Kullanıcı',
                            style: const TextStyle(
                              color: Color(0xFF9A7A89),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _isJoining ? null : _leaveList,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Listeden Ayrıl'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),

              TextField(
                controller: _inviteCodeController,
                onChanged: (_) => setState(() {}),
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

              if (isCurrentListCode)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Bu senin aktif listen.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isJoining || isCurrentListCode ? null : _joinList,
                  icon: _isJoining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(
                    isCurrentListCode
                        ? 'Zaten Bu Listedesin'
                        : (_isJoining ? 'Katılınıyor...' : 'Listeye Katıl'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isCurrentListCode
                        ? Colors.grey
                        : const Color(0xFFD96BA7),
                    side: BorderSide(
                      color: isCurrentListCode
                          ? Colors.grey.shade300
                          : const Color(0xFFD96BA7),
                    ),
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
