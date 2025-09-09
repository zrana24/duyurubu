import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;

  BluetoothConnection? get connection => _connection;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnecting => _isConnecting;

  void setConnection(BluetoothConnection? connection, BluetoothDevice? device) {
    _connection = connection;
    _connectedDevice = device;
    _isConnecting = false;
    notifyListeners();
  }

  void setConnecting(bool connecting) {
    _isConnecting = connecting;
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close();
    }
    catch (e) {
      print('Bağlantı kesme hatası: $e');
    }
    finally {
      _connection = null;
      _connectedDevice = null;
      _isConnecting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}