import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Shared bottom navigation bar used by the main [HomePage] shell.
///
/// Contains 4 navigation items (Home, Explore, Market, Profile) with a
/// centre scan FAB that triggers index 2.
class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final String homeLabel, exploreLabel, marketLabel, profileLabel;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.homeLabel,
    required this.exploreLabel,
    required this.marketLabel,
    required this.profileLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.brown900.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: homeLabel,
                index: 0,
                selected: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                label: exploreLabel,
                index: 1,
                selected: selectedIndex,
                onTap: onTap,
              ),

              // ── Centre FAB — NO label underneath ──────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.brown900,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brown900.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.filter_center_focus_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),

              _NavItem(
                icon: Icons.shopping_bag_outlined,
                label: marketLabel,
                index: 3,
                selected: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: profileLabel,
                index: 4,
                selected: selectedIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index, selected;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    final color = isSelected ? AppColors.brown700 : Colors.grey.shade400;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
