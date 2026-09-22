import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';

/// Displays a modal dialog with a full data table for a history record.
void showHistoryDetailModal(
  BuildContext context,
  Map<String, dynamic> record,
  HistoryProvider history,
  SettingsProvider settings,
) {
  showDialog(
    context: context,
    builder: (dialogCtx) {
      return HistoryDetailDialog(
        record: record,
        history: history,
        settings: settings,
      );
    },
  );
}

class HistoryDetailDialog extends StatelessWidget {
  final Map<String, dynamic> record;
  final HistoryProvider history;
  final SettingsProvider settings;

  const HistoryDetailDialog({
    super.key,
    required this.record,
    required this.history,
    required this.settings,
  });

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

  @override
  Widget build(BuildContext context) {
    final rawCsv = record['sensor_data'] as String? ?? '';
    final List<List<dynamic>> parsedRows = const CsvToListConverter().convert(rawCsv);

    List<dynamic> headers = [];
    List<List<dynamic>> dataRows = [];

    if (parsedRows.isNotEmpty) {
      headers = parsedRows.first;
      if (parsedRows.length > 1) {
        dataRows = parsedRows.sublist(1);
      }
    }

    final sampleType = record['sample_type'] as String? ?? '-';
    final sampleName = record['sample_name'] as String? ?? '-';
    final profileName = record['profile_name'] as String? ?? '-';
    final timestamp = _formatTimestamp(record['timestamp'] as String? ?? '');
    final count = record['sampling_count'] ?? dataRows.length;

    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: screenSize.width * 0.85,
        height: screenSize.height * 0.85,
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 800),
        child: Column(
          children: [
            // MODAL HEADER
            _buildModalHeader(context, sampleName, timestamp),

            // CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // METADATA SUMMARY CARDS
                    _buildMetadataGrid(sampleType, sampleName, profileName, timestamp, count),
                    const SizedBox(height: 16),

                    // SECTION TITLE
                    Row(
                      children: [
                        const Icon(Icons.table_chart_outlined, size: 18, color: AppColors.primaryRed),
                        const SizedBox(width: 8),
                        Text(
                          "Tabel Reading Sensor (${dataRows.length} Data Point)",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkSlate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // TABLE CONTAINER
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: parsedRows.isEmpty
                            ? const Center(
                                child: Text(
                                  "Data sensor kosong.",
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            : _buildDataTable(headers, dataRows),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // MODAL FOOTER
            _buildModalFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context, String sampleName, String timestamp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.analytics_outlined, color: AppColors.primaryRed, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Detail Sampling: $sampleName",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Waktu Sampling: $timestamp",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textDark),
            tooltip: "Tutup",
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataGrid(
    String sampleType,
    String sampleName,
    String profileName,
    String timestamp,
    dynamic count,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _buildMetaItem("Jenis Sampel", sampleType, isBadge: true),
          _buildMetaItem("Nama Sampel", sampleName),
          _buildMetaItem("Profil Setting", profileName),
          _buildMetaItem("Jumlah Data Point", "$count"),
          _buildMetaItem("Waktu", timestamp),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, {bool isBadge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        isBadge
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkSlate,
                ),
              ),
      ],
    );
  }

  Widget _buildDataTable(List<dynamic> headers, List<List<dynamic>> dataRows) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.surfaceLight),
                    dataRowMinHeight: 38,
                    dataRowMaxHeight: 42,
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                    columns: [
                      const DataColumn(
                        label: Text(
                          "No",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.darkSlate,
                          ),
                        ),
                      ),
                      ...headers.map(
                        (header) => DataColumn(
                          label: Text(
                            "$header",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows: List.generate(dataRows.length, (index) {
                      final row = dataRows[index];
                      final isEven = index % 2 == 0;
                      return DataRow(
                        color: WidgetStateProperty.all(
                          isEven ? Colors.white : AppColors.background,
                        ),
                        cells: [
                          DataCell(
                            Text(
                              "${index + 1}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ...row.map(
                            (val) => DataCell(
                              Text(
                                "$val",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkSlate,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalFooter(BuildContext context) {
    final recordId = record['id'] as int?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Export CSV Button
          if (recordId != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text("Export CSV", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final filePath = await history.exportToCsv(recordId, settings);
                if (!context.mounted) return;
                if (filePath != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("CSV berhasil di-export: $filePath"),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
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
              },
            )
          else
            const SizedBox.shrink(),

          // Close Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkSlate,
              side: const BorderSide(color: AppColors.borderDark),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Tutup", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
