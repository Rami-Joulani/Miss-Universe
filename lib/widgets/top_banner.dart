import 'package:flutter/material.dart';

class TopBanner extends StatelessWidget {
  const TopBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0F0A), // deep brown
              Color(0xFF4E3A2E), // bronze fade
            ],
          ),
          border: Border(
            bottom: BorderSide(color: Color(0xFFC8A46D), width: 1.5),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/miss_universe_logo.jpeg',
              height: 40,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(width: 16),
            const Text(
              'Miss Universe',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
