import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnecting => _isConnecting;

  void setConnecting(bool connecting) {
    _isConnecting = connecting;
    notifyListeners();
  }

  // Add this missing method that ConnectPage is calling
  void setConnectedDevice(BluetoothDevice? device) {
    _connectedDevice = device;
    notifyListeners();
  }

  // Cihaza bağlan
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting || _connectedDevice != null) return;

    try {
      setConnecting(true);
      await device.connect(autoConnect: false, timeout: Duration(seconds: 8));
      _connectedDevice = device;

      // Bağlantı durumu değişikliklerini dinle
      device.connectionState.listen((state) {
        print('Cihaz bağlantı durumu: $state');
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          notifyListeners();
        }
      });

      notifyListeners();
    } catch (e) {
      print('Bağlantı hatası: $e');
      _connectedDevice = null;
      notifyListeners();
    } finally {
      setConnecting(false);
    }
  }

  // Cihazdan bağlantıyı kes
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print('Bağlantı kesme hatası: $e');
      } finally {
        _connectedDevice = null;
        _isConnecting = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}