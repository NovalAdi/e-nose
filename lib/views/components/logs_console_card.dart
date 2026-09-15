import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../providers/sampling_provider.dart';

class LogsConsoleCard extends StatefulWidget {
  final SamplingProvider sampler;

  const LogsConsoleCard({
    super.key,
    required this.sampler,
  });

  @override
  State<LogsConsoleCard> createState() => _LogsConsoleCardState();
}

class _LogsConsoleCardState extends State<LogsConsoleCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sampler = widget.sampler;

    // Auto-scroll when logs update
    _scrollToBottom();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.terminalBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.terminal, color: AppColors.terminalCyan, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "LOG TERMINAL SISTEM",
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
                onPressed: () => sampler.clearLogs(),
              )
            ],
          ),
          const Divider(color: Color(0xFF1E293B), height: 16),

          // Log List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: sampler.logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    sampler.logs[index],
                    style: const TextStyle(
                      fontFamily: "Courier",
                      color: AppColors.terminalCyan,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),

          // Countdown Timer Overlay if active
          if (sampler.countdownSeconds > 0)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "PROSES AKTIF - Hitung Mundur: ${sampler.countdownSeconds} detik",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
