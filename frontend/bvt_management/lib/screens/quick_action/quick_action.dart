import 'package:flutter/material.dart';

import '../home/Home_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const QuickActionsGrid({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
        children: [
          QuickActionCard(icon: Icons.pets_rounded, label: 'អ្នកជំងឺ', subtitle: 'Patient', accent: ChartColors.teal, tint: ChartColors.tealTint, onTap: () => onNavigate(1)),
          QuickActionCard(icon: Icons.medication_outlined, label: 'ថ្នាំ', subtitle: 'Medicine', accent: ChartColors.amber, tint: ChartColors.amberTint, onTap: () => onNavigate(2)),
          QuickActionCard(icon: Icons.inventory_2_outlined, label: 'ស្តុក', subtitle: 'Stock', accent: ChartColors.tealDeep, tint: ChartColors.tealTint, onTap: () => onNavigate(2)),
          QuickActionCard(icon: Icons.shopping_cart_outlined, label: 'ការលក់', subtitle: 'Sale', accent: ChartColors.amber, tint: ChartColors.amberTint, onTap: () => onNavigate(4)),
        ],
      );
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final Color accent, tint;
  final VoidCallback onTap;
  const QuickActionCard({super.key, required this.icon, required this.label, required this.subtitle, required this.accent, required this.tint, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: ChartColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: ChartColors.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: accent, size: 20)),
              const Spacer(),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ChartColors.ink)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: ChartColors.inkSoft)),
            ]),
          ),
        ),
      );
}
