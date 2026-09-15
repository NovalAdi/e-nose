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

  /// Close controllers when service is destroyed
  void dispose() {
    disconnect();
    _lineStreamController.close();
    _statusStreamController.close();
  }
}
