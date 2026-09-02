import 'package:ceyizim_plus/core/extensions/currency_extensions.dart';
import 'package:ceyizim_plus/core/formatters/turkish_currency_input_formatter.dart';
import 'package:ceyizim_plus/features/budget/data/budget_providers.dart';
import 'package:ceyizim_plus/features/items/data/item_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetProvider);
    final itemsAsync = ref.watch(allItemsProvider);
    final spent =
        itemsAsync.value
            ?.where((item) => item.isPurchased)
            .fold<double>(0, (sum, item) => sum + (item.purchasedPrice ?? 0)) ??
        0;
    final planned =
        itemsAsync.value
            ?.where((item) => !item.isPurchased)
            .fold<double>(0, (sum, item) => sum + (item.plannedPrice ?? 0)) ??
        0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(title: const Text('Bütçe Planı')),
      body: budgetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(budgetProvider),
        ),
        data: (budget) {
          final totalExpected = spent + planned;
          final remaining = budget == null ? null : budget - spent;
          final progress = budget == null || budget <= 0
              ? 0.0
              : (spent / budget).clamp(0.0, 1.0);

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD95F9F), Color(0xFFFF8BB8)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toplam bütçe',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      budget?.toCurrency() ?? 'Henüz belirlenmedi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      remaining == null
                          ? 'Harcama ilerlemesi için bütçe belirle'
                          : remaining >= 0
                          ? '${remaining.toCurrency()} kullanılabilir'
                          : '${(-remaining).toCurrency()} bütçe aşımı',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _MetricCard('Harcanan', spent.toCurrency())),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard('Planlanan', planned.toCurrency()),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MetricCard('Tahmini toplam', totalExpected.toCurrency()),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [TurkishCurrencyInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Yeni toplam bütçe',
                  hintText: budget?.toInt().toString(),
                  prefixText: '₺ ',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.savings_outlined),
                label: const Text('Bütçeyi Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final value = double.tryParse(_controller.text.replaceAll('.', ''));
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir bütçe girmelisin.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(budgetRepositoryProvider).updateBudget(value);
      ref.invalidate(budgetProvider);
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bütçe güncellendi.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bütçe kaydedilemedi: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFDCEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8A6B79))),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42),
            const SizedBox(height: 12),
            const Text('Bütçe bilgisi alınamadı.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
