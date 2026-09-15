import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../providers/settings_provider.dart';

/// Shows a dialog allowing user to save current sensor config under a profile name
void showSaveProfileDialog(
  BuildContext context,
  SettingsProvider settings, {
  VoidCallback? onSaved,
}) {
  final defaultName = "Setting ${settings.profileNames.length + 1}";
  final controller = TextEditingController(text: defaultName);

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Simpan Profil Konfigurasi",
          style: TextStyle(color: AppColors.darkSlate, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Masukkan nama profil konfigurasi sensor ini untuk disimpan ke dropdown:",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.darkSlate),
              decoration: const InputDecoration(
                labelText: "Nama Profil Setting",
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
            onPressed: () {
              final name = controller.text.trim();
              settings.saveCurrentAsProfile(name);
              Navigator.pop(dialogCtx);
              if (onSaved != null) {
                onSaved();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Konfigurasi berhasil disimpan sebagai '${settings.currentProfile}'!")),
              );
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

/// Shows a confirmation dialog when user switches tab with unsaved config changes
void showUnsavedChangesDialog(
  BuildContext context,
  SettingsProvider settings, {
  required VoidCallback onDiscard,
  required VoidCallback onSavedAndContinue,
}) {
  final defaultName = "Setting ${settings.profileNames.length + 1}";
  final controller = TextEditingController(text: defaultName);

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Pengaturan Belum Disimpan",
          style: TextStyle(color: AppColors.darkSlate, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Anda memiliki perubahan konfigurasi sensor yang belum disimpan. Masukkan nama profil untuk menyimpan perubahan sebelum berpindah halaman:",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.darkSlate),
              decoration: const InputDecoration(
                labelText: "Nama Profil Setting",
                labelStyle: TextStyle(color: AppColors.primaryRed),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderDark)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primaryRed)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              settings.discardChanges();
              onDiscard();
            },
            child: const Text("Abaikan Perubahan", style: TextStyle(color: AppColors.danger)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Batal", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = controller.text.trim();
              settings.saveCurrentAsProfile(name);
              Navigator.pop(dialogCtx);
              onSavedAndContinue();
            },
            child: const Text("Simpan & Lanjut", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}
