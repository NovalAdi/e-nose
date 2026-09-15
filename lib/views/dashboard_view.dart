import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/settings_provider.dart';
import '../providers/sampling_provider.dart';
import 'components/sidebar_panel.dart';
import 'components/top_nav_bar.dart';
import 'components/prediction_summary_card.dart';
import 'components/action_controls_grid.dart';
import 'components/logs_console_card.dart';
import 'components/sensor_config_tab.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _activeTab = 0; // 0 = Main Dashboard, 1 = Config

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final sampler = Provider.of<SamplingProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // LEFT SIDEBAR: Navigation & Device Controls
          SidebarPanel(
            settings: settings,
            sampler: sampler,
          ),

          // RIGHT CONTENT PANEL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TOP NAV BAR (CAPSULE TAB SWITCHER & ACTIVE STATUS)
                TopNavBar(
                  activeTab: _activeTab,
                  onTabChanged: (index) => setState(() => _activeTab = index),
                  settings: settings,
                ),

                // MAIN VIEW CONTROLLER
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: IndexedStack(
                      index: _activeTab,
                      children: [
                        _buildMainDashboardTab(settings, sampler),
                        SensorConfigTab(settings: settings),
                      ],
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

  /// Dashboard tab layout: Prediction & Actions on left, Logs Console on right
  Widget _buildMainDashboardTab(
    SettingsProvider settings,
    SamplingProvider sampler,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Prediction Summary & Actions Grid
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: PredictionSummaryCard(sampler: sampler),
              ),
              const SizedBox(height: 16),
              Expanded(
                flex: 5,
                child: ActionControlsGrid(settings: settings, sampler: sampler),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Right Column: System Logs Console
        Expanded(
          flex: 6,
          child: LogsConsoleCard(sampler: sampler),
        ),
      ],
    );
  }
}
