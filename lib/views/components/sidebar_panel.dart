import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sampling_provider.dart';

class SidebarPanel extends StatefulWidget {
  final SettingsProvider settings;
  final SamplingProvider sampler;

  const SidebarPanel({
    super.key,
    required this.settings,
    required this.sampler,
  });

  @override
  State<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends State<SidebarPanel> {
  late TextEditingController _intervalController;
  late TextEditingController _sampleNameController;
  late TextEditingController _deviceIdController;
  late TextEditingController _csvDirectoryController;

  @override
  void initState() {
    super.initState();
    _intervalController = TextEditingController(
      text: widget.settings.samplingInterval.toString().replaceAll(
        RegExp(r'\.0$'),
        '',
      ),
    );
    _sampleNameController = TextEditingController(
      text: widget.settings.sampleName,
    );
    _deviceIdController = TextEditingController(text: widget.settings.deviceId);
    _csvDirectoryController = TextEditingController(
      text: widget.settings.csvExportDirectory,
    );

    widget.settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) {
      if (widget.settings.csvExportDirectory != _csvDirectoryController.text) {
        _csvDirectoryController.text = widget.settings.csvExportDirectory;
      }
      if (widget.settings.sampleName != _sampleNameController.text) {
        _sampleNameController.text = widget.settings.sampleName;
      }
      if (widget.settings.deviceId != _deviceIdController.text) {
        _deviceIdController.text = widget.settings.deviceId;
      }
    }
  }

  @override
  void didUpdateWidget(covariant SidebarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      oldWidget.settings.removeListener(_onSettingsChanged);
      widget.settings.addListener(_onSettingsChanged);
    }
    if (oldWidget.settings.sampleName != widget.settings.sampleName &&
        _sampleNameController.text != widget.settings.sampleName) {
      _sampleNameController.text = widget.settings.sampleName;
    }
    if (oldWidget.settings.deviceId != widget.settings.deviceId &&
        _deviceIdController.text != widget.settings.deviceId) {
      _deviceIdController.text = widget.settings.deviceId;
    }
    if (widget.settings.csvExportDirectory != _csvDirectoryController.text) {
      _csvDirectoryController.text = widget.settings.csvExportDirectory;
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    _intervalController.dispose();
    _sampleNameController.dispose();
    _deviceIdController.dispose();
    _csvDirectoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final sampler = widget.sampler;

    return Container(
      width: 290,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          right: BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/t-nose-logo.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.psychology,
                    color: AppColors.primaryRed,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable Settings Cards
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Port Serial & Device ID Card
                  _buildPortAndDeviceCard(settings, sampler),
                  const SizedBox(height: 12),

                  // CSV Export Folder Card (Di atas pengaturan menit sampling)
                  _buildCsvFolderCard(settings, sampler),
                  const SizedBox(height: 12),

                  // Sampling Interval Card
                  _buildIntervalCard(settings, sampler),
                  const SizedBox(height: 12),

                  // Sample Type Dropdown Card
                  _buildSampleTypeCard(settings, sampler),
                  const SizedBox(height: 12),

                  // Sample Name & Counter Card
                  _buildSampleNameCard(settings, sampler),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Connection Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: settings.selectedPort.isEmpty
                  ? Colors.grey[400]
                  : (settings.isConnected
                        ? AppColors.textDark
                        : AppColors.primaryRed),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: sampler.isRunning || settings.selectedPort.isEmpty
                ? null
                : () async {
                    final msg = await settings.toggleConnection();
                    sampler.addLog(msg);
                    if (context.mounted) {
                      final isError = msg.contains('Gagal');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: isError ? AppColors.danger : AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  settings.isConnected ? Icons.link_off : Icons.link,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  settings.isConnected ? "Disconnect Port" : "Connect Port",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Emergency Stop Button
          if (sampler.isRunning) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => sampler.stopAll(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    "BATAL / STOP",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortAndDeviceCard(
    SettingsProvider settings,
    SamplingProvider sampler,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PORT SERIAL:",
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: settings.availablePorts.contains(settings.selectedPort)
                      ? settings.selectedPort
                      : null,
                  hint: const Text(
                    "Pilih Port...",
                    style: TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: AppColors.darkSlate,
                    fontSize: 13,
                  ),
                  underline: const SizedBox(),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.primaryRed,
                  ),
                  items: settings.availablePorts.map((port) {
                    return DropdownMenuItem<String>(
                      value: port,
                      child: Text(
                        settings.getPortDescription(port),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: sampler.isRunning
                      ? null
                      : (val) {
                          if (val != null) {
                            settings.selectedPort = val;
                          }
                        },
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.primaryRed,
                  size: 20,
                ),
                onPressed: sampler.isRunning
                    ? null
                    : () => settings.refreshPortsList(),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 16),
          const Text(
            "DEVICE ID:",
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _deviceIdController,
            style: const TextStyle(color: AppColors.darkSlate, fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
              hintText: "Device ID",
              hintStyle: TextStyle(color: Colors.black38),
            ),
            onChanged: (val) => settings.deviceId = val,
          ),
        ],
      ),
    );
  }

  Widget _buildCsvFolderCard(
    SettingsProvider settings,
    SamplingProvider sampler,
  ) {
    final hasCustom =
        settings.csvExportDirectory.isNotEmpty &&
        settings.defaultExportDirectory.isNotEmpty &&
        settings.csvExportDirectory != settings.defaultExportDirectory;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "FOLDER SIMPAN CSV:",
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasCustom)
                InkWell(
                  onTap: sampler.isRunning
                      ? null
                      : () async {
                          await settings.resetCsvExportDirectoryToDefault();
                          _csvDirectoryController.text =
                              settings.csvExportDirectory;
                        },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      "Reset Default",
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Tooltip(
                    message: settings.csvExportDirectory.isEmpty
                        ? "Default: Folder Download"
                        : settings.csvExportDirectory,
                    child: TextField(
                      controller: _csvDirectoryController,
                      enabled: !sampler.isRunning,
                      style: const TextStyle(
                        color: AppColors.darkSlate,
                        fontSize: 12,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: "Folder Download (Default)",
                        hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                      onChanged: (val) {
                        settings.csvExportDirectory = val;
                      },
                    ),
                  ),
                ),
                IconButton(
                  tooltip: "Pilih Folder",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  icon: const Icon(
                    Icons.folder_open,
                    color: AppColors.primaryRed,
                    size: 18,
                  ),
                  onPressed: sampler.isRunning
                      ? null
                      : () async {
                          final picked = await settings
                              .pickCsvExportDirectory();
                          if (picked) {
                            _csvDirectoryController.text =
                                settings.csvExportDirectory;
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                hasCustom ? Icons.check_circle_outline : Icons.info_outline,
                size: 11,
                color: hasCustom ? Colors.green[700] : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  hasCustom
                      ? "Custom folder aktif"
                      : "Default: Folder Download sistem",
                  style: TextStyle(
                    color: hasCustom ? Colors.green[700] : AppColors.textMuted,
                    fontSize: 9.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalCard(
    SettingsProvider settings,
    SamplingProvider sampler,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "INTERVAL SAMPLING (DETIK):",
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _intervalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: !sampler.isRunning,
                    style: const TextStyle(
                      color: AppColors.darkSlate,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: "1",
                      hintStyle: TextStyle(color: Colors.black38),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        settings.samplingInterval = parsed;
                      }
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "detik",
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 11,
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

  Widget _buildSampleTypeCard(
    SettingsProvider settings,
    SamplingProvider sampler,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "JENIS SAMPEL:",
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value:
                    settings.sampleTypes.contains(settings.selectedSampleType)
                    ? settings.selectedSampleType
                    : settings.sampleTypes.first,
                isExpanded: true,
                isDense: true,
                dropdownColor: Colors.white,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.primaryRed,
                ),
                style: const TextStyle(
                  color: AppColors.darkSlate,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                items: settings.sampleTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: AppColors.darkSlate,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: sampler.isRunning
                    ? null
                    : (val) {
                        if (val != null) {
                          settings.selectedSampleType = val;
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleNameCard(
    SettingsProvider settings,
    SamplingProvider sampler,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "NAMA ${settings.selectedSampleType.toUpperCase()}:",
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Ke-${settings.samplingCount}",
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: TextField(
              controller: _sampleNameController,
              enabled: !sampler.isRunning,
              style: const TextStyle(
                color: AppColors.darkSlate,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
                border: InputBorder.none,
                hintText: "Contoh: Hitam, Melati, Oolong...",
                hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
              ),
              onChanged: (val) {
                settings.sampleName = val;
              },
            ),
          ),
        ],
      ),
    );
  }
}
