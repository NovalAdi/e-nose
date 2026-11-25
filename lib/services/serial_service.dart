import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _subscription;
  
  final _lineStreamController = StreamController<String>.broadcast();
  final _statusStreamController = StreamController<String>.broadcast();
  
  String _buffer = '';
  bool _isConnected = false;
  String _currentPortName = '';

  Stream<String> get lineStream => _lineStreamController.stream;
  Stream<String> get statusStream => _statusStreamController.stream;
  bool get isConnected => _isConnected;
  String get currentPortName => _currentPortName;

  /// Get list of available COM ports on the system
  List<String> getAvailablePorts() {
    try {
      return SerialPort.availablePorts;
    } catch (e) {
      debugPrint("Error listing serial ports: $e");
      return [];
    }
  }

  /// Get descriptive name for a port
  String getPortDescription(String portName) {
    try {
      final port = SerialPort(portName);
      final desc = port.description ?? '';
      final manuf = port.manufacturer ?? '';
      if (desc.isNotEmpty) {
        return "$portName - $desc ${manuf.isNotEmpty ? '($manuf)' : ''}";
      }
      return portName;
    } catch (_) {
      return portName;
    }
  }

  /// Connect to a serial port
  bool connect(String portName, {int baudRate = 9600}) {
    if (_isConnected) {
      disconnect();
    }

    try {
      debugPrint("Connecting to serial port: $portName");
      final port = SerialPort(portName);
      
      if (!port.openReadWrite()) {
        debugPrint("Failed to open port $portName in Read/Write mode.");
        _statusStreamController.add("Connection failed");
        return false;
      }

      // Configure port settings
      final config = port.config;
      config.baudRate = baudRate;
      config.bits = 8;
      config.stopBits = 1;
      config.parity = SerialPortParity.none;
      config.setFlowControl(SerialPortFlowControl.none);
      port.config = config;

      _port = port;
      _currentPortName = portName;
      _isConnected = true;
      _statusStreamController.add("Connected");

      // Start reading stream
      _buffer = '';
      _reader = SerialPortReader(port);
      _subscription = _reader!.stream.listen(
        (Uint8List data) {
          final chunk = utf8.decode(data, allowMalformed: true);
          _buffer += chunk;
          
          while (_buffer.contains('\n')) {
            final index = _buffer.indexOf('\n');
            final line = _buffer.substring(0, index).trim();
            _buffer = _buffer.substring(index + 1);
            if (line.isNotEmpty) {
              _lineStreamController.add(line);
            }
          }
        },
        onError: (error) {
          debugPrint("Serial read error: $error");
          disconnect();
        },
        onDone: () {
          debugPrint("Serial reader stream closed.");
          disconnect();
        },
      );

      return true;
    } catch (e) {
      debugPrint("Serial connection exception: $e");
      disconnect();
      return false;
    }
  }

  /// Disconnect from current serial port
  void disconnect() {
    _statusStreamController.add("Not connected");
    
    _subscription?.cancel();
    _subscription = null;
    
    try {
      _reader?.close();
    } catch (_) {}
    _reader = null;

    try {
      if (_port != null && _port!.isOpen) {
        _port!.close();
      }
    } catch (_) {}
    
    _port?.dispose();
    _port = null;
    
    _isConnected = false;
    _currentPortName = '';
    _buffer = '';
    debugPrint("Disconnected from serial port.");
  }

  /// Write string data (like '1', '2', '3') to the port
  bool writeString(String data) {
    if (_port == null || !_isConnected || !_port!.isOpen) {
      debugPrint("Cannot write: port is not connected or open.");
      return false;
    }

    try {
      final bytes = utf8.encode(data);
      final written = _port!.write(Uint8List.fromList(bytes));
      return written > 0;
    } catch (e) {
      debugPrint("Error writing to serial port: $e");
      return false;
    }
  }

  /// Send a command and wait for the device's acknowledgment.
  ///
  /// - Sends [command] and waits for a line starting with "ACK:" within [timeout].
  /// - If no response, resends up to [maxRetries] times (default 3) with
  ///   [retryInterval] (default 500 ms) between attempts.
  /// - If all retries fail, reconnect to the port and repeat the cycle
  ///   until [maxCycles] (default 3) or success.
  /// - Returns `true` if ACK received, `false` after all cycles exhausted.
  Future<bool> sendCommandWithAck(String command, {
    Duration timeout = const Duration(milliseconds: 1500),
    int maxRetries = 3,
    int retryInterval = 500,
    int maxCycles = 3,
  }) async {
    int cycles = 0;
    while (cycles < maxCycles) {
      int failed = 0;
      while (failed < maxRetries) {
        writeString(command);
        final response = await _waitForAck(timeout);
        if (response != null) return true;
        failed++;
        if (failed < maxRetries) {
          await Future.delayed(Duration(milliseconds: retryInterval));
        }
      }
      // All retries failed: reconnect and retry the cycle
      cycles++;
      if (cycles >= maxCycles) return false;
      await _reconnectAndReset();
      if (!isConnected) {
        return false;
      }
    }
    return false;
  }

  /// Wait for a single line starting with "ACK:" from the device.
  /// Returns the ACK line, or `null` if no response within [timeout].
  Future<String?> _waitForAck(Duration timeout) async {
    final completer = Completer<String?>();
    Timer? timer;
    late StreamSubscription<String> subscription;

    subscription = _lineStreamController.stream.listen((line) {
      if (line.startsWith('ACK:') && !completer.isCompleted) {
        completer.complete(line);
        subscription.cancel();
        timer?.cancel();
      }
    });

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
        subscription.cancel();
      }
    });

    return completer.future;
  }

  /// Reconnect to the same port, resetting internal state.
  Future<void> _reconnectAndReset() async {
    disconnect();
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentPortName.isNotEmpty) {
      connect(_currentPortName);
    }
  }

  /// Close controllers when service is destroyed
  void dispose() {
    disconnect();
    _lineStreamController.close();
    _statusStreamController.close();
  }
}
