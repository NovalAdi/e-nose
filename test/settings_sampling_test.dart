import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/services/serial_service.dart';
import 'package:flutter_app/services/api_service.dart';

void main() {
  test('SettingsProvider sampleName, sampleType and counter reset test', () {
    final settings = SettingsProvider(SerialService(), ApiService());

    expect(settings.selectedSampleType, 'Teh');
    expect(settings.sampleName, 'Hitam');
    expect(settings.samplingCount, 0);

    // Increment count
    settings.incrementSamplingCount();
    expect(settings.samplingCount, 1);
    settings.incrementSamplingCount();
    expect(settings.samplingCount, 2);

    // Changing sample name resets counter
    settings.sampleName = 'Melati';
    expect(settings.sampleName, 'Melati');
    expect(settings.samplingCount, 0);

    // Increment again
    settings.incrementSamplingCount();
    expect(settings.samplingCount, 1);

    // Changing sample type resets counter
    settings.selectedSampleType = 'Kopi';
    expect(settings.selectedSampleType, 'Kopi');
    expect(settings.samplingCount, 0);
  });

  test('SettingsProvider csvExportDirectory setting and reset test', () async {
    final settings = SettingsProvider(SerialService(), ApiService());

    // Initially can be set to custom folder
    const customDir = '/custom/path/to/csv_folder';
    settings.csvExportDirectory = customDir;
    expect(settings.csvExportDirectory, customDir);

    // Can update to another folder
    const anotherDir = 'C:\\Data\\E-Nose_Output';
    settings.csvExportDirectory = anotherDir;
    expect(settings.csvExportDirectory, anotherDir);
  });
}
