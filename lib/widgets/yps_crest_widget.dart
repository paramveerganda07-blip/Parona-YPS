import 'package:flutter/material.dart';

class YpsCrestWidget extends StatelessWidget {
  final double size;

  const YpsCrestWidget({
    super.key,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/yps_crest_official.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/yps_crest.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.shield,
                  color: const Color(0xFFD4AF37),
                  size: size * 0.8,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
