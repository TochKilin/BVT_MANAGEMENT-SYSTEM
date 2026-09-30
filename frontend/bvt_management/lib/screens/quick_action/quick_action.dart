import 'package:flutter/material.dart';

import '../home/Home_screen.dart';

// Grid of shortcut cards
class QuickActionsGrid extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const QuickActionsGrid({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        QuickActionCard(
          icon: Icons.pets_rounded,
          label: 'អ្នកជំងឺ',
          subtitle: 'Patient',
          accent: const Color(0xFFFFFFFF),
          tint: const Color(0xFF0E6B5C),
          onTap: () => onNavigate(1),
        ),
        QuickActionCard(
          icon: Icons.medication_outlined,
          label: 'ថ្នាំ',
          subtitle: 'Medicine',
          accent: const Color(0xFFFFFFFF),
          tint: const Color(0xFF0E6B5C),
          onTap: () => onNavigate(2),
        ),
        QuickActionCard(
          icon: Icons.inventory_2_outlined,
          label: 'ស្តុក',
          subtitle: 'Stock',
          accent: const Color(0xFFFFFFFF),
          tint: const Color(0xFF0E6B5C),
          onTap: () => onNavigate(11),
        ),
        QuickActionCard(
          icon: Icons.shopping_cart_outlined,
          label: 'ការលក់',
          subtitle: 'Sale',
          accent: const Color(0xFFFFFFFF),
          tint: const Color(0xFF0E6B5C),
          onTap: () => onNavigate(4),
        ),
        QuickActionCard(
          icon: Icons.receipt_long_outlined,
          label: 'វេជ្ជបញ្ជា',
          subtitle: 'Prescription',
          accent: const Color(0xFFFFFFFF),
          tint: const Color(0xFF0E6B5C),
          onTap: () => onNavigate(9),
        ),
        QuickActionCard(
          icon: Icons.medical_services_outlined,
          label: 'ការព្យាបាល',
          subtitle: 'Treatment',
          accent: const Color(0xFFFFFFFF),
          tint: const Color(0xFF0E6B5C),
          onTap: () => onNavigate(10),
        ),
      ],
    );
  }
}

/// A single tappable
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAF9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const Spacer(),
              // Title
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A202C),
                ),
              ),
              // Subtitle
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF4A5568)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
