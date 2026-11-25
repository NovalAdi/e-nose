# flutter_app (T-NOSE V2)

Aplikasi desktop Flutter untuk **elektronics nose / gas sensing**. Aplikasi ini membaca data sensor lewat port serial,
mengendalikan aliran gas (inhale/exhale/stop), mengirim data ke model prediksi AI (Flask API), lalu menyimpan
riwayat sampling di database lokal (SQLite) yang bisa diekspor ke CSV.

---

## Fitur

- **Sampling** — ambil data sensor sesuai interval, simpan 60 titik pembacaan
- **Predict** — prediksi sampel lewat API AI ( klasifikasi + skor TVC )
- **Flushing** — bersihkan gas/sensor (embersiasi 60 detik)
- **Testing** — uji respons sensor singkat 3 detik
- **Riwayat Sampling** — lihat, prediksi ulang, export CSV, hapus dari DB
- **Konfigurasi Sensor** — Import/Export preset `.hbb`, pilih profil sensor (10 pin A0–A9), custom nama sensor
- **Penanganan port serial** — daftar port, koneksi/deskoneksi, auto-select port pertama
- **Dashboard live** — chart data sensor real-time, log terminal, ringkasan prediksi

---

## Tech Stack

| Bagian | Teknologi |
|---|---|
| UI | Flutter (Material 3, desktop window manager) |
| Manajemen state | Provider |
| Serial port | `flutter_libserialport` |
| HTTP API | `dio` |
| Database | `sqflite` (FFI, desktop) |
| CSV | `csv` package |
| File picker | `file_picker` |
| Grafik | `fl_chart` |
| Window | `window_manager` |

---

## Struktur Project

```
lib/
├── main.dart                 # Entry: init window, DB, services, providers
├── models/sensor_config.dart # SensorConfig: pin, enabled, name, type
├── utils/
│   └── sensor_parser.dart    # Parse serial line, hitung rata-rata, format log
├── services/
│   ├── serial_service.dart   # Koneksi serial, read/write, stream baris
│   ├── api_service.dart      # Klien HttpClient → /predict, health, devices
│   └── database_helper.dart  # SQLite: sampling_history, sensor_profiles, app_settings
├── providers/
│   ├── settings_provider.dart  # Profil sensor, port, sample type/name, export folder, API url
│   ├── sampling_provider.dart  # State machine: idle/sampling/predicting/flushing/testing
│   └── history_provider.dart   # CRUD riwayat, export CSV ke folder
├── views/
│   ├── dashboard_view.dart      # Master layout: sidebar + tab switch + content
│   ├── components/
│   │   ├── action_controls_grid.dart  # Tombol Sampling/Predict/Flushing/Testing
│   │   ├── prediction_summary_card.dart
│   │   ├── logs_console_card.dart
│   │   ├── sensor_config_tab.dart
│   │   ├── history_tab.dart
│   │   ├── top_nav_bar.dart
│   │   └── sidebar_panel.dart
│   └── dialogs/
│       ├── save_profile_dialog.dart
│       ├── import_config_dialog.dart
│       ├── export_config_dialog.dart
│       └── history_detail_dialog.dart
```

---

## Cara Menjalankan

1. Install Flutter SDK (SDK ^3.11.5) dan pastikan `flutter` ada di PATH.
2. Buka project:

   ```bash
   cd /Users/user/Magang KK AITM/e-nose copy
   flutter pub get
   ```

3. Jalankan:

   ```bash
   flutter run
   ```

> Catatan: aplikasi ini dibuat untuk **desktop** (macOS/Windows/Linux) karena pakai `window_manager` dan
> `sqflite_common_ffi`.

---

## Alur Kerja Aplikasi

> Lihat detail lengkap alur di bagian berikut.

### 1. Startup

1. `WidgetsFlutterBinding.ensureInitialized()` → siapkan binding Flutter.
2. `window_manager` inisialisasi + window diperbesar (desktop).
3. `DatabaseHelper().initDatabase()` → buka SQLite `enose_history.db` dengan tabel:
   - `sampling_history`
   - `sensor_profiles`
   - `app_settings`
4. `SerialService()` + `ApiService()` (Dio) diinisialisasi.
   - URL API default: `https://enose-backend-gn0a.onrender.com`
5. `SettingsProvider()` → load profil default, port serial, setting aplikasi.
6. `SamplingProvider(serialService, apiService)` dibuat, lalu di-set ke `HistoryProvider`.
7. `MaterialApp` (tema T-Nose Red) → tampil `DashboardView`.

### 2. Koneksi Port Serial

1. Pilih port dari dropdown (auto-select ke port pertama kalau kosong).
2. Klik **Connect Port** → `SerialService.connect(port)`:
   - Buka port read/write, set 9600 8N1, no parity, no flow control
   - Start `SerialPortReader` stream; baris dipisah dengan `\n`
3. Status kabel berubah (connect/disconnect), tombol dinonaktifkan saat proses berjalan.

### 3. Sampling

Saat tombol **Sampling** ditekan (hanya dari status `idle`, memerlukan koneksi port):

1. State → `sampling`, reset data titik, prediksi, skor.
2. Log: `Mulai sampling #N [Jenis - Nama] - Interval: X detik`.
3. **Tahap 1** — kirim perintah STOP via `sendCommandWithAck('3')`:
   - Tunggu ACK dari alat (retry 3× × 500 ms, reconnect otomatis jika gagal 3 siklus).
   - Setelah ACK diterima → tunggu 3 detik.
4. **Tahap 2** — kirim perintah INHALE via `sendCommandWithAck('1')`:
   - Tunggu ACK dari alat.
   - Countdown `samplingInterval` detik.
5. **Tahap 3** — kirim perintah STOP via `sendCommandWithAck('3')`:
   - Tunggu ACK dari alat.
   - Tunggu 20 detik.
6. **Tahap 4** — kumpulkan **60 baris** dari `lineStream`:
   - Setiap baris diparse lewat `SensorParser.parseLine(line, enabledPins)`
   - 60 baris → subscription dibatalkan, selesai.
7. **Tahap 5** — simpan ke DB lewat `HistoryProvider.addRecord()`:
   - CSV 60 baris (header = nama sensor), simpan header JSON + metadata
   - `samplingCount` di-increment.
8. **Tahap 6** — `runFlushSequence()` (embersiasi 60s + stop 5s).
9. State → `idle`, log `"Akhir sampling."`

> Catatan: setiap perintah sekarang **menunggu ACK** sebelum melanjutkan.
> Total estimasi tetap ± **interval + 88–95 detik** (interval default 60 → ±150–158s)
> karena `sendCommandWithAck` menambahkan waktu tunggu ACK (maks 1500 ms/cek).

### 4. Predict

Mirip Sampling sampai tahap 4, kemudian:

1. Hitung rata-rata tiap sensor (`SensorParser.calculateAverages`) dari 60 baris.
2. `POST /predict` ke API: `{'data': [10 nilai rata-rata]}`.
3. Tangkap `result['prediction']` → simpan ke `predictionCategory`, `tvcScore`.
4. Flush bersih 65 detik.
5. State → idle.

> Total estimasi: **3 (stop ACK) + 3s + 1 (inhale ACK) + interval + 60 + 65 ≈ interval + 128 detik** (interval default 60 → ±190s).

### 5. Flushing

1. Kirim perintah EXHALE via `sendCommandWithAck('2')` → tunggu ACK.
2. Countdown 60 detik.
3. Kirim perintah STOP via `sendCommandWithAck('3')` → tunggu ACK.
4. Tunggu 5 detik.
5. State → `idle`.

### 6. Testing

1. Countdown 3 detik → log `"Testing selesai."` → state `idle`.

### 7. STOP / Batal

1. Kirim perintah STOP via `sendCommandWithAck('3')` → tunggu ACK (retry 3× 500 ms, reconnect otomatis).
2. Batalkan countdown & subscription → state `idle`.

### 8. Stream Data Langsung (Live Dashboard)

- `SerialService.lineStream` selalu dipantau di konstruktor `SamplingProvider`.
- Setiap baris → `SensorParser.parseLine(line, allPins)` → `_currentLiveValues`
- Simpan ke `_liveChartPoints` (maks 50) → `notifyListeners()` → chart & log re-render.

### 9. Riwayat Sampling (tab 2)

1. `HistoryProvider` load otomatis di constructor → `getAllHistory()` dari SQLite.
2. Tabel: No, Waktu, Jenis, Nama Sampel, Profil, #, Aksi.
3. Aksi per record:
   - **Prediksi Ulang** — parsing CSV → rata-rata 10 sensor → `apiService.predict()` → AlertDialog.
   - **Lihat Tabel Data** — modal detail (info + CSV mentah).
   - **Export CSV** — ke folder custom (jika di-set) atau folder Download; nama `sampling_<type>_<name>_<count>_<timestamp>.csv`.
   - **Hapus / Hapus Semua** — konfirmasi.

### 10. Konfigurasi Sensor (tab 1)

1. Toolbar: **Import Settings (.hbb)**, **Export Settings (.hbb)**.
2. Dropdown profil: default `Config Sensor V2`, `Setting Default Pin`, `Setting 5 Sensor`.
3. Setiap row A0..A9:
   - Type: `OFF` / `Default` / `Custom`
   - Nama sensor (custom hanya aktif kalau type = Custom)
   - Checkbox enable
   - Mengubah → `markModified()` → status *New* / unsaved.
4. **Simpan** → `saveCurrentAsProfile(name)` → simpan ke DB.
5. **Import .hbb** — parse baris `PIN=ENABLED,NAME,TYPE` → profil baru otomatis.
6. **Export .hbb** — tulis konfigurasi aktif ke file.

### 11. Format Data Serial

Baris data: `A0:val@A1:val@...` dipisah `@`, nilai dipisah `:`.
Diproses oleh `SensorParser.parseLine(line, enabledPins)` yang hanya menerima pin yang enabled.

### 12. API Backend

- **POST** `/predict` — body `{'data': [double, ...10]}` → response `{'prediction': 'F'/'E'/..., 'score': ...}`
- `POST /enose_greentea/health` — cek status server
- `GET /enose_greentea/devices` — daftar devices

### 13. Command-Response Protocol & Retry Mechanism

Setiap perintah (`1`, `2`, `3`) dikirim lewat `sendCommandWithAck(...)` di `SerialService`.
Intinya: **tunggu ACK dari alat sebelum lanjut**; kalau tak ada, retry; kalau tetap gagal,
reconnect port dan ulang siklus.

#### 13.1 Alur `sendCommandWithAck`

1. Kirim perintah ke alat.
2. Tunggu baris yang berawalan `"ACK:"` dalam waktu `[timeout]` (default **1500 ms**).
3. Jika timeout → kirim ulang perintah (retry) sampai **3 kali** dengan jarak **500 ms**.
4. Jika 3x terakhir tetap tak ada respon → **reconnect port**, lalu ulang siklus
   (maksimal `[maxCycles]`, default **3**).
5. Jika semua siklus gagal → mengembalikan `false` → alur dilaporkan dan dibatalkan.

#### 13.2 Parameter default

| Parameter | Default | Keterangan |
|---|---|---|
| `timeout` | 1500 ms | Waktu tunggu ACK per command |
| `maxRetries` | 3 | Maksimal retry per command |
| `retryInterval` | 500 ms | Jarak antar retry |
| `maxCycles` | 3 | Maksimal siklus reconnect-otomatis sebelum gagal |

#### 13.3 Contoh pemanggilan

- STOP: `await _serialService.sendCommandWithAck('3')`
- Flushing: `await _serialService.sendCommandWithAck('2')` → 60s → `await _serialService.sendCommandWithAck('3')`
- STOP dari sidebar: `_serialService.sendCommandWithAck('3')` (log peringatan jika gagal)

#### 13.4 Catatan

- Data sensor (`A0:val@...@A9:val@#`) diabaikan oleh `sendCommandWithAck`; hanya baris yang
  berawalan `"ACK:"` yang dianggap respon.
- Protokol perintah serial tetap: `1` = inhale, `2` = exhale, `3` = stop.

---

## Protokol Perintah Serial

| Perintah | Arti |
|---|---|
| `1` | Inhale (tarik gas) |
| `2` | Exhale (embersi) |
| `3` | Stop (hentikan pompa) |

---

## Status Machine

| Status | Dipicu oleh | Diakhiri oleh |
|---|---|---|
| `idle` | startup, stopAll, flush selesai, prediksi selesai | — |
| `sampling` | startSampling | selesai flush |
| `predicting` | startPrediction | selesai flush |
| `flushing` | startFlushing | runFlushSequence |
| `testing` | startTesting | 3s selesai |

---

## Persyaratan Hardware

- Port serial (COM) yang mendukung `flutter_libserialport`
- 9600 baud, 8 data bit, 1 stop bit, no parity, no flow control
- Sensor aktif dari profil konfigurasi (default 10 sensor A0–A9)

---

## Troubleshooting

1. **Sampling/Predict gagal** → pastikan port serial sudah di-connect.
2. **Server tidak merespons** → cek koneksi API (default ke Render). Timeout receive 90s.
3. **Data serial hilang / tidak terbaca** → pastikan format `A0:val@A1:val@...` dan `\n` sebagai separator.
4. **Port tidak muncul** → restart aplikasi, pastikan driver USB/CH340/FTDI terpasang.
5. **Export CSV gagal** → folder tujuan harus bisa ditulis (tidak ada izin).
