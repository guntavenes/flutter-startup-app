import 'package:flutter/material.dart';
import 'package:flutter_startup_app/features/templates/presentation/template_preview_screen.dart';
import '../domain/template_item.dart';
import '../data/ceyiz_templates.dart';

class TemplateSelectionScreen extends StatelessWidget {
  const TemplateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: const Text('Hazır Çeyiz Listeleri'),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kendine uygun listeyi seç 🌸',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1E26),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Hazır şablonlardan başlayabilir,\nsonradan ürün ekleyip çıkarabilirsin.',
              style: TextStyle(
                color: Color(0xFF8A6B79),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 22),

            _buildTemplateCard(
              context,
              title: 'Basic',
              subtitle: 'Temel ev ihtiyaçları',
              icon: Icons.home_outlined,
              color: const Color(0xFFFFB74D),
              itemCount: CeyizTemplates.basicItems.length,
              items: CeyizTemplates.basicItems
            ),

            _buildTemplateCard(
              context,
              title: 'Standart',
              subtitle: 'Orta seviye tam çeyiz',
              icon: Icons.favorite_border_rounded,
              color: const Color(0xFFD96BA7),
              itemCount: CeyizTemplates.standardItems.length,
              items: CeyizTemplates.standardItems
            ),

            _buildTemplateCard(
              context,
              title: 'Premium',
              subtitle: 'Her şey dahil premium liste',
              icon: Icons.workspace_premium_outlined,
              color: const Color(0xFF7ACFA6),
              itemCount: CeyizTemplates.premiumItems.length,
              items: CeyizTemplates.premiumItems
            ),
          ],
        ),
      ),
    );
  }

Widget _buildTemplateCard(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required int itemCount,
  required List<TemplateItem> items,
}) {
    return GestureDetector(
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplatePreviewScreen(
          title: title,
          items: items,
        ),
      ),
    );
  },
  child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C1E26),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8A6B79),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '$itemCount ürün',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A6B79)),
        ],
      ),
  ),
    );
  }
}
