import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, this.height = 112, this.count = 3});
  final double height;
  final int count;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'İçerik yükleniyor',
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => Column(
            children: List.generate(
              widget.count,
              (index) => Container(
                height: widget.height,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    dark ? Colors.grey.shade800 : Colors.grey.shade200,
                    dark ? Colors.grey.shade700 : Colors.grey.shade100,
                    _controller.value,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
