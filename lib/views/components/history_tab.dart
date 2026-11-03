import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/api_service.dart';
import '../../utils/sensor_parser.dart';
import 'package:csv/csv.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final history = Provider.of<HistoryProvider>(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TOOLBAR
        _buildToolbar(context, history),
        const SizedBox(height: 16),

        // DATA TABLE
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: history.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  )
                : history.history.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(context, history, settings),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, HistoryProvider history) {
    return Row(
      children: [
        // Title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.primaryRed,
              ),
              const SizedBox(width: 8),
              Text(
                "Riwayat Sampling (${history.history.length})",
                style: const TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Refresh Button
        _ToolbarButton(
          icon: Icons.refresh_rounded,
          label: "Refresh",
          onPressed: () => history.loadHistory(),
        ),
        const SizedBox(width: 8),

        // Delete All Button
        _ToolbarButton(
          icon: Icons.delete_sweep_outlined,
          label: "Hapus Semua",
          isDanger: true,
          onPressed: history.history.isEmpty
              ? null
              : () => _confirmDeleteAll(context, history),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.science_outlined,
              size: 48,
              color: AppColors.borderDark,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Belum Ada Riwayat Sampling",
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Mulai sampling dari Dashboard untuk menyimpan data ke riwayat.",
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    HistoryProvider history,
    SettingsProvider settings,
  ) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border(
              bottom: BorderSide(color: AppColors.borderDark, width: 1),
            ),
          ),
          child: const Row(
            children: [
              SizedBox(width: 40, child: Text("No", style: _headerStyle)),
              Expanded(flex: 3, child: Text("Waktu", style: _headerStyle)),
              Expanded(flex: 2, child: Text("Jenis", style: _headerStyle)),
              Expanded(
                flex: 2,
                child: Text("Nama Sampel", style: _headerStyle),
              ),
              Expanded(flex: 2, child: Text("Profil", style: _headerStyle)),
              SizedBox(width: 50, child: Text("#", style: _headerStyle)),
              SizedBox(width: 140, child: Text("Aksi", style: _headerStyle)),
            ],
          ),
        ),

        // Table Body
        Expanded(
          child: ListView.builder(
            itemCount: history.history.length,
            itemBuilder: (context, index) {
              final record = history.history[index];
              final isEven = index % 2 == 0;
              return _buildHistoryRow(
                context,
                record,
                index + 1,
                isEven,
                history,
                settings,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryRow(
    BuildContext context,
    Map<String, dynamic> record,
    int number,
    bool isEven,
    HistoryProvider history,
    SettingsProvider settings,
  ) {
    final timestamp = record['timestamp'] as String? ?? '';
    final formattedTime = _formatTimestamp(timestamp);

    return Material(
      color: isEven ? Colors.white : AppColors.background,
      child: InkWell(
        onTap: () => showHistoryDetailModal(context, record, history, settings),
        hoverColor: AppColors.primaryRed.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  "$number",
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  formattedTime,
                  style: const TextStyle(
                    color: AppColors.darkSlate,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record['sample_type'] ?? '-',
                    style: const TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  record['sample_name'] ?? '-',
                  style: const TextStyle(
                    color: AppColors.darkSlate,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  record['profile_name'] ?? '-',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  "${record['sampling_count'] ?? '-'}",
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                child: Row(
                  children: [
                    // Predict from History Button
                    _ActionIconButton(
                      icon: Icons.psychology_outlined,
                      tooltip: "Prediksi Ulang",
                      color: Colors.indigo,
                      onPressed: () =>
                          _runPredictionFromHistory(context, record, settings),
                    ),
                    const SizedBox(width: 4),
                    // View Table Modal Button
                    _ActionIconButton(
                      icon: Icons.table_chart_outlined,
                      tooltip: "Lihat Tabel Data",
                      color: AppColors.primaryRed,
                      onPressed: () => showHistoryDetailModal(
                        context,
                        record,
                        history,
                        settings,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Export CSV Button
                    _ActionIconButton(
                      icon: Icons.download_rounded,
                      tooltip: "Export CSV",
                      color: AppColors.success,
                      onPressed: () => _exportCsv(
                        context,
                        record['id'] as int,
                        history,
                        settings,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Delete Button
                    _ActionIconButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: "Hapus",
                      color: AppColors.danger,
                      onPressed: () =>
                          _confirmDelete(context, record['id'] as int, history),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _runPredictionFromHistory(
    BuildContext context,
    Map<String, dynamic> record,
    SettingsProvider settings,
  ) async {
    final String csvData = record['sensor_data'] as String;

    try {
      // 1. Convert CSV to List of Maps
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvData,
      );
      if (rows.length < 2) throw Exception("Format data CSV tidak valid.");

      final headers = rows[0].map((e) => e.toString()).toList();
      final List<Map<String, double>> dataPoints = [];

      // Create a map from pin names to indices (A0, A1, etc.)
      // We assume headers are sensor names, so we need to map back to pins
      final sensorNamesMap = settings.getSensorNamesMap();
      final pinToHeader = sensorNamesMap;

      for (int i = 1; i < rows.length; i++) {
        final Map<String, double> point = {};
        for (int j = 0; j < headers.length; j++) {
          final pinName = pinToHeader.entries
              .firstWhere(
                (entry) => entry.value == headers[j],
                orElse: () => MapEntry(headers[j], ''),
              )
              .key;
          point[pinName] = double.tryParse(rows[i][j].toString()) ?? 0.0;
        }
        dataPoints.add(point);
      }

      // 2. Calculate Averages
      final allPins = [
        'A0',
        'A1',
        'A2',
        'A3',
        'A4',
        'A5',
        'A6',
        'A7',
        'A8',
        'A9',
      ];
      final averages = SensorParser.calculateAverages(dataPoints, allPins);
      final averageValuesList = allPins
          .map((pin) => averages[pin] ?? 0.0)
          .toList();

      // 3. Call API
      final apiService = ApiService();
      final result = await apiService.predict(sensorValues: averageValuesList);
      final String prediction = result['prediction'].toString();

      // 4. Show Result
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text("Hasil Prediksi Ulang"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Data riwayat dianalisis ulang oleh AI:"),
              const SizedBox(height: 16),
              Text(
                "Grade $prediction",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tutup"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.danger),
      );
    }
  }

  void showHistoryDetailModal(
    BuildContext context,
    Map<String, dynamic> record,
    HistoryProvider history,
    SettingsProvider settings,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.table_chart_rounded,
              color: AppColors.primaryRed,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Detail Sampling",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _detailRow(
                        "Waktu",
                        _formatTimestamp(record['timestamp'] ?? '-'),
                      ),
                      _detailRow("Jenis Sampel", record['sample_type'] ?? '-'),
                      _detailRow("Nama Sampel", record['sample_name'] ?? '-'),
                      _detailRow("Profil", record['profile_name'] ?? '-'),
                      _detailRow(
                        "Jumlah Sampling",
                        "${record['sampling_count'] ?? '-'}",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Data Sensor (CSV)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      record['sensor_data'] ?? '-',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.darkSlate,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "Tutup",
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _exportCsv(context, record['id'] as int, history, settings);
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text("Export CSV"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');
      return "$day/$month/$year $hour:$minute:$second";
    } catch (_) {
      return iso;
    }
  }

  void _exportCsv(
    BuildContext context,
    int id,
    HistoryProvider history,
    SettingsProvider settings,
  ) async {
    final filePath = await history.exportToCsv(id, settings);
    if (!context.mounted) return;

    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("CSV berhasil di-export: $filePath"),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal meng-export file CSV."),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, int id, HistoryProvider history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              "Hapus Record",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin menghapus record ini? Data yang dihapus tidak bisa dikembalikan.",
          style: TextStyle(fontSize: 13, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "Batal",
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              history.deleteRecord(id);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, HistoryProvider history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              "Hapus Semua Riwayat",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus semua ${history.history.length} record? Data yang dihapus tidak bisa dikembalikan.",
          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "Batal",
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              history.deleteAllRecords();
            },
            child: const Text("Hapus Semua"),
          ),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    color: AppColors.textDark,
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
  );
}

/// Small toolbar button widget
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isDanger;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.textDark;
    final bgColor = isDanger
        ? AppColors.danger.withValues(alpha: 0.08)
        : AppColors.surfaceLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: onPressed == null ? AppColors.background : bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: onPressed == null ? AppColors.borderDark : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: onPressed == null ? AppColors.borderDark : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small action icon button for table rows
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}
