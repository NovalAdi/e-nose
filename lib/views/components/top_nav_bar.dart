import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../dialogs/save_profile_dialog.dart';

class TopNavBar extends StatelessWidget {
  final int activeTab;
  final Function(int) onTabChanged;
  final SettingsProvider settings;

  const TopNavBar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.settings,
  });

  void _handleTabSwitch(BuildContext context, int targetIndex) {
    if (activeTab == targetIndex) return;

    if (activeTab == 1 && settings.hasUnsavedChanges) {
      showUnsavedChangesDialog(
        context,
        settings,
        onDiscard: () => onTabChanged(targetIndex),
        onSavedAndContinue: () => onTabChanged(targetIndex),
      );
    } else {
      onTabChanged(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildCapsuleTab(
            context: context,
            index: 0,
            icon: Icons.dashboard_outlined,
            title: "Dashboard Utama",
          ),
          const SizedBox(width: 10),
          _buildCapsuleTab(
            context: context,
            index: 1,
            icon: Icons.tune_outlined,
            title: "Pengaturan Sensor",
          ),
          const Spacer(),

          // Active Sample & Status Pill Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: settings.isConnected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${settings.selectedSampleType}: ${settings.sampleName}",
                  style: const TextStyle(
                    color: AppColors.darkSlate,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Sample ke-${settings.samplingCount}",
                    style: const TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleTab({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
  }) {
    final isActive = activeTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTabSwitch(context, index),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryRed : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : AppColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textMuted,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
