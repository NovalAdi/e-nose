import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../providers/sampling_provider.dart';

class PredictionSummaryCard extends StatelessWidget {
  final SamplingProvider sampler;

  const PredictionSummaryCard({
    super.key,
    required this.sampler,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.success;
    String textDesc = "Baik (Sehat)";
    String statusDetail = "Kondisi sampel terdeteksi dalam batas normal.";

    if (sampler.predictionCategory == 'F') {
      statusColor = AppColors.danger;
      textDesc = "Rusak / Spoiled";
      statusDetail = "Kondisi sampel terdeteksi terkontaminasi atau rusak.";
    } else if (sampler.predictionCategory == 'E') {
      statusColor = AppColors.warning;
      textDesc = "Marginal / Acceptable";
      statusDetail = "Kondisi sampel mendekati ambang batas toleransi.";
    } else if (sampler.predictionCategory == '-') {
      statusColor = AppColors.textMuted;
      textDesc = "Belum Ada Prediksi";
      statusDetail = "Jalankan proses Sampling atau Predict untuk analisis.";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ROW 1: KATEGORI PREDIKSI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "KATEGORI PREDIKSI",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      textDesc,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusDetail,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  sampler.predictionCategory,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Divider(color: AppColors.border, height: 20),

          // ROW 2: NILAI PREDIKSI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "NILAI PREDIKSI",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Hasil Nilai Prediksi",
                    style: TextStyle(
                      color: AppColors.darkSlate,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Hasil estimasi nilai dari model AI",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  sampler.tvcScore > 0 ? sampler.tvcScore.toStringAsFixed(2) : "-",
                  style: const TextStyle(
                    color: AppColors.darkSlate,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
