import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/providers/sampling_provider.dart';
import 'package:flutter_app/services/serial_service.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/views/dashboard_view.dart';
import 'package:flutter_app/views/components/prediction_summary_card.dart';
import 'package:flutter_app/views/components/action_controls_grid.dart';
import 'package:flutter_app/views/components/logs_console_card.dart';

void main() {
  testWidgets('DashboardView sub-components rendering test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final serialService = SerialService();
    final apiService = ApiService();
    final settingsProvider = SettingsProvider(serialService, apiService);
    final samplingProvider = SamplingProvider(serialService, apiService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: samplingProvider),
        ],
        child: const MaterialApp(
          home: DashboardView(),
        ),
      ),
    );
    await tester.pump();

    // Verify main components are present in widget tree
    expect(find.byType(PredictionSummaryCard), findsOneWidget);
    expect(find.byType(ActionControlsGrid), findsOneWidget);
    expect(find.byType(LogsConsoleCard), findsOneWidget);
    expect(find.text('Sampling'), findsOneWidget);
    expect(find.text('Predict'), findsOneWidget);
    expect(find.text('Flushing'), findsOneWidget);
    expect(find.text('Testing'), findsOneWidget);

    // Verify CSV folder setting field exists above interval sampling
    expect(find.text('FOLDER SIMPAN CSV:'), findsOneWidget);
    expect(find.text('INTERVAL SAMPLING (MENIT):'), findsOneWidget);
  });
}
