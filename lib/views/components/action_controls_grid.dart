import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sampling_provider.dart';

class ActionControlsGrid extends StatelessWidget {
  final SettingsProvider settings;
  final SamplingProvider sampler;

  const ActionControlsGrid({
    super.key,
    required this.settings,
    required this.sampler,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ROW 1: Sampling & Predict
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ActionButtonCard(
                  label: "Sampling",
                  subLabel: "Ambil data & CSV",
                  icon: Icons.play_arrow_rounded,
                  onPressed: sampler.isRunning
                      ? null
                      : () => sampler.startSampling(settings),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ActionButtonCard(
                  label: "Predict",
                  subLabel: "Prediksi Sampel AI",
                  icon: Icons.psychology_outlined,
                  onPressed: sampler.isRunning
                      ? null
                      : () => sampler.startPrediction(settings),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ROW 2: Flushing & Testing
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ActionButtonCard(
                  label: "Flushing",
                  subLabel: "Bersihkan sensor",
                  icon: Icons.air_rounded,
                  onPressed: sampler.isRunning ? null : () => sampler.startFlushing(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ActionButtonCard(
                  label: "Testing",
                  subLabel: "Uji respon sensor",
                  icon: Icons.science_outlined,
                  onPressed: sampler.isRunning ? null : () => sampler.startTesting(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ActionButtonCard extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  const ActionButtonCard({
    super.key,
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Container(
      decoration: BoxDecoration(
        color: disabled ? AppColors.background : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: disabled ? AppColors.borderDark : AppColors.primaryRed,
          width: 1.5,
        ),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.primaryRed.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.primaryRed.withValues(alpha: 0.04),
          splashColor: AppColors.primaryRed.withValues(alpha: 0.10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: disabled ? AppColors.border : AppColors.primaryRed.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: disabled ? const Color(0xFF94A3B8) : AppColors.primaryRed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: disabled ? const Color(0xFF94A3B8) : AppColors.primaryRed,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: disabled ? AppColors.borderDark : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
