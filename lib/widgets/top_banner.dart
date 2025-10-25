import 'package:flutter/material.dart';

class TopBanner extends StatelessWidget {
  final VoidCallback? onMenu;
  const TopBanner({super.key, this.onMenu});

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
            colors: [Color(0xFF1A0F0A), Color(0xFF4E3A2E)],
          ),
          border: Border(bottom: BorderSide(color: Color(0xFFC8A46D), width: 1.5)),
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            if (onMenu != null)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: onMenu,
                tooltip: 'Menu',
              ),
            Image.asset('assets/miss_universe_logo.jpeg', height: 40, filterQuality: FilterQuality.high),
            const SizedBox(width: 16),
            const Text(
              'Miss Universe',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}