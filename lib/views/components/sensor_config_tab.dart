import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../dialogs/save_profile_dialog.dart';
import '../dialogs/import_config_dialog.dart';
import '../dialogs/export_config_dialog.dart';

class SensorConfigTab extends StatelessWidget {
  final SettingsProvider settings;

  const SensorConfigTab({
    super.key,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final pins = ['A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9'];

    return Column(
      children: [
        // Import / Export Settings Toolbar & Profile Dropdown
        _buildToolbar(context),
        const SizedBox(height: 20),

        // Config Table Card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: pins.length,
              itemBuilder: (context, index) {
                final pin = pins[index];
                final config = settings.sensorConfigs[pin];
                if (config == null) return const SizedBox();

                return SensorConfigRow(
                  pin: pin,
                  type: config.type,
                  name: config.name,
                  enabled: config.enabled,
                  onTypeChanged: (newType) => settings.onSensorTypeChange(pin, newType),
                  onNameChanged: (newName) => settings.updateSensorName(pin, newName),
                  onEnabledChanged: (newVal) => settings.onCheckboxChange(pin, newVal),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.file_upload, size: 18),
          label: const Text("Import Settings (.hbb)"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceLight,
            foregroundColor: AppColors.darkSlate,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.borderDark),
            ),
          ),
          onPressed: () => showImportConfigDialog(context, settings),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.file_download, size: 18),
          label: const Text("Export Settings (.hbb)"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceLight,
            foregroundColor: AppColors.darkSlate,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.borderDark),
            ),
          ),
          onPressed: () => showExportConfigDialog(context, settings),
        ),
        const Spacer(),

        // Profile Dropdown & Save Button
        Row(
          children: [
            const Text(
              "Pilih Profil Setting: ",
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: DropdownButton<String>(
                value: settings.profileNames.contains(settings.currentProfile)
                    ? settings.currentProfile
                    : "New",
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryRed),
                style: const TextStyle(
                  color: AppColors.darkSlate,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                items: [
                  ...settings.profileNames.map((name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    );
                  }),
                  if (settings.currentProfile == "New" || settings.hasUnsavedChanges)
                    const DropdownMenuItem<String>(
                      value: "New",
                      child: Text(
                        "New (Belum Disimpan)",
                        style: TextStyle(color: AppColors.primaryRed, fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
                onChanged: (val) {
                  if (val != null && val != "New") {
                    settings.selectProfile(val);
                  }
                },
              ),
            ),

            // Save Button if New or Unsaved
            if (settings.hasUnsavedChanges || settings.currentProfile == "New") ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 16, color: Colors.white),
                label: const Text(
                  "Simpan",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => showSaveProfileDialog(context, settings),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class SensorConfigRow extends StatefulWidget {
  final String pin;
  final String type;
  final String name;
  final bool enabled;
  final Function(String) onTypeChanged;
  final Function(String) onNameChanged;
  final Function(bool) onEnabledChanged;

  const SensorConfigRow({
    super.key,
    required this.pin,
    required this.type,
    required this.name,
    required this.enabled,
    required this.onTypeChanged,
    required this.onNameChanged,
    required this.onEnabledChanged,
  });

  @override
  State<SensorConfigRow> createState() => _SensorConfigRowState();
}

class _SensorConfigRowState extends State<SensorConfigRow> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
  }

  @override
  void didUpdateWidget(covariant SensorConfigRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && _nameController.text != widget.name) {
      _nameController.text = widget.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Pin Label
          SizedBox(
            width: 50,
            child: Text(
              widget.pin,
              style: const TextStyle(
                color: AppColors.darkSlate,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // Sensor Type Dropdown
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Text("Tipe: ", style: TextStyle(color: AppColors.textDark, fontSize: 12)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: widget.type,
                    items: ['OFF', 'Default', 'Custom'].map((t) {
                      return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)));
                    }).toList(),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: AppColors.darkSlate, fontSize: 12),
                    underline: const SizedBox(),
                    onChanged: (val) {
                      if (val != null) {
                        widget.onTypeChanged(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Sensor Name Input
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const Text("Nama: ", style: TextStyle(color: AppColors.textDark, fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _nameController,
                      enabled: widget.type == 'Custom',
                      style: TextStyle(
                        color: widget.type == 'Custom' ? AppColors.darkSlate : Colors.black38,
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: widget.onNameChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Checkbox Enable
          Checkbox(
            value: widget.enabled,
            activeColor: AppColors.primaryRed,
            onChanged: (val) {
              if (val != null) {
                widget.onEnabledChanged(val);
              }
            },
          ),
        ],
      ),
    );
  }
}
