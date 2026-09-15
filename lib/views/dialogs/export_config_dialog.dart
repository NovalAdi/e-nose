import 'dart:io';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../providers/settings_provider.dart';

/// Shows a dialog to export sensor settings to .hbb file
void showExportConfigDialog(BuildContext context, SettingsProvider settings) {
  final controller = TextEditingController(text: "config sensor v2.hbb");

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Export Settings",
          style: TextStyle(color: AppColors.darkSlate, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Simpan konfigurasi settings ini ke file .hbb di folder project saat ini:",
              style: TextStyle(color: AppColors.textDark, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.darkSlate),
              decoration: const InputDecoration(
                labelText: "Nama File",
                labelStyle: TextStyle(color: AppColors.primaryRed),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderDark)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryRed)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Batal", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogCtx);
              final path = "${Directory.current.path}/${controller.text}";
              final success = await settings.exportSettings(path);
              
              if (success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text("Konfigurasi sensor berhasil diekspor ke: $path")),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text("Gagal mengekspor file konfigurasi.")),
                );
              }
            },
            child: const Text("Export", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}
