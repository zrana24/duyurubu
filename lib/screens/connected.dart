import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue_plus;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
as bluetooth_serial;
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum BluetoothServiceState {
  disconnected,
  connecting,
  connected,
  weakSignal,
  error,
}

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  // Bluetooth state
  blue_plus.BluetoothAdapterState _bluetoothState =
      blue_plus.BluetoothAdapterState.unknown;
  List<blue_plus.BluetoothDevice> _pairedDevicesList = [];
  List<blue_plus.ScanResult> _scanResults = [];

  // Connection state
  BluetoothServiceState _connectionState = BluetoothServiceState.disconnected;
  blue_plus.BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  bool _isScanning = false;
  bool _connectionLocked = false;

  // Data storage
  Map<String, int?> _rssiValues = {};
  List<bluetooth_serial.BluetoothDevice> _bondedDevicesList = [];
  Map<String, String> _deviceNamesCache = {};

  // Stream controllers
  final _bluetoothStateController =
  StreamController<blue_plus.BluetoothAdapterState>.broadcast();
  final _connectionStateController =
  StreamController<BluetoothServiceState>.broadcast();
  final _devicesController =
  StreamController<List<blue_plus.BluetoothDevice>>.broadcast();
  final _scanResultsController =
  StreamController<List<blue_plus.ScanResult>>.broadcast();

  // Getters
  blue_plus.BluetoothAdapterState get bluetoothState => _bluetoothState;
  List<blue_plus.BluetoothDevice> get pairedDevices => _pairedDevicesList;
  List<blue_plus.BluetoothDevice> get nearbyDevices =>
      _scanResults.map((r) => r.device).toList();
  BluetoothServiceState get connectionState => _connectionState;
  blue_plus.BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnecting => _isConnecting;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectedDevice != null && !_isConnecting;
  Map<String, int?> get rssiValues => _rssiValues;

  // Streams
  Stream<blue_plus.BluetoothAdapterState> get bluetoothStateStream =>
      _bluetoothStateController.stream;
  Stream<BluetoothServiceState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<List<blue_plus.BluetoothDevice>> get devicesStream =>
      _devicesController.stream;
  Stream<List<blue_plus.ScanResult>> get scanResultsStream =>
      _scanResultsController.stream;

  StreamSubscription<List<blue_plus.ScanResult>>? _scanSubscription;
  StreamSubscription<blue_plus.BluetoothConnectionState>?
  _connectionSubscription;
  Timer? _continuousScanTimer;

  // Permission handling
  Future<bool> requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses =
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    } catch (e) {
      print('❌ İzin hatası: $e');
      return false;
    }
  }

  // Bluetooth Başlatma
  Future<void> initializeBluetooth() async {
    try {
      bool hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        print('❌ Bluetooth izinleri gerekli');
        return;
      }

      blue_plus.FlutterBluePlus.adapterState.listen((state) async {
        _bluetoothState = state;
        _bluetoothStateController.add(state);

        if (state == blue_plus.BluetoothAdapterState.on) {
          await _getBondedDevices();
          await _getPairedDevices();
          _startContinuousScanning();
        } else {
          _stopScan();
          _updateConnectionState(BluetoothServiceState.disconnected);
        }
      });

      final initialState = await blue_plus.FlutterBluePlus.adapterState.first;
      _bluetoothState = initialState;
      _bluetoothStateController.add(initialState);

      if (_bluetoothState == blue_plus.BluetoothAdapterState.on) {
        await _getBondedDevices();
        await _getPairedDevices();
        _startContinuousScanning();
      }
    } catch (e) {
      print('❌ Bluetooth başlatma hatası: $e');
    }
  }

  // Eşleşmiş Cihazları Getirme
  Future<void> _getBondedDevices() async {
    try {
      List<bluetooth_serial.BluetoothDevice> bondedDevices =
      await bluetooth_serial.FlutterBluetoothSerial.instance
          .getBondedDevices();

      _bondedDevicesList = bondedDevices;

      for (var bondedDevice in _bondedDevicesList) {
        try {
          blue_plus.BluetoothDevice device = blue_plus.BluetoothDevice.fromId(
            bondedDevice.address,
          );

          if (!_pairedDevicesList.any(
                (d) => d.remoteId.str == bondedDevice.address,
          )) {
            _pairedDevicesList.add(device);
          }

          if (bondedDevice.name != null && bondedDevice.name!.isNotEmpty) {
            _deviceNamesCache[bondedDevice.address] = bondedDevice.name!;
          }
        } catch (e) {
          print('❌ Cihaz ekleme hatası: $e');
        }
      }

      _devicesController.add(_pairedDevicesList);
    } catch (e) {
      print('❌ Eşleşmiş cihazlar alınamadı: $e');
    }
  }

  // Bağlı Cihazları Getirme
  Future<void> _getPairedDevices() async {
    try {
      List<blue_plus.BluetoothDevice> connectedDevices =
      await blue_plus.FlutterBluePlus.connectedDevices;

      for (var device in connectedDevices) {
        if (!_pairedDevicesList.any((d) => d.remoteId == device.remoteId)) {
          _pairedDevicesList.add(device);
        }

        String deviceId = device.remoteId.str;
        if (device.platformName.isNotEmpty &&
            !_deviceNamesCache.containsKey(deviceId)) {
          _deviceNamesCache[deviceId] = device.platformName;
        }
      }

      _devicesController.add(_pairedDevicesList);
    } catch (e) {
      print('❌ Bağlı cihazlar alınamadı: $e');
    }
  }

  // Otomatik Tarama Sistemi
  void _startContinuousScanning() {
    _continuousScanTimer?.cancel();
    _continuousScanTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      if (_bluetoothState != blue_plus.BluetoothAdapterState.on ||
          _isConnecting)
        return;

      if (!_isScanning) {
        startScan();
        Future.delayed(Duration(seconds: 10), _stopScan);
      }
    });
  }

  // Tarama Sistemi
  void startScan() {
    if (_isScanning ||
        _bluetoothState != blue_plus.BluetoothAdapterState.on ||
        _isConnecting) {
      return;
    }

    _isScanning = true;
    _scanResults.clear();

    _scanSubscription?.cancel();
    _scanSubscription = blue_plus.FlutterBluePlus.scanResults.listen(
          (results) {
        for (blue_plus.ScanResult result in results) {
          final index = _scanResults.indexWhere(
                (r) => r.device.remoteId == result.device.remoteId,
          );
          if (index >= 0) {
            _scanResults[index] = result;
          } else {
            _scanResults.add(result);
          }
          _rssiValues[result.device.remoteId.str] = result.rssi;

          String deviceId = result.device.remoteId.str;
          String advName = result.advertisementData.advName;
          if (advName.isNotEmpty && !_deviceNamesCache.containsKey(deviceId)) {
            _deviceNamesCache[deviceId] = advName;
          }
        }
        _scanResultsController.add(_scanResults);
      },
      onError: (error) {
        print('❌ Tarama hatası: $error');
        _isScanning = false;
      },
    );

    blue_plus.FlutterBluePlus.startScan(
      timeout: Duration(seconds: 10),
      androidUsesFineLocation: false,
    );
  }

  void _stopScan() {
    if (_isScanning) {
      blue_plus.FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _isScanning = false;
    }
  }

  // Cihaz adını getir
  String getDeviceDisplayName(blue_plus.BluetoothDevice device) {
    String deviceId = device.remoteId.str;

    if (_deviceNamesCache.containsKey(deviceId)) {
      return _deviceNamesCache[deviceId]!;
    }

    for (var bondedDevice in _bondedDevicesList) {
      if (bondedDevice.address == deviceId) {
        if (bondedDevice.name != null && bondedDevice.name!.isNotEmpty) {
          return bondedDevice.name!;
        }
      }
    }

    if (device.platformName.isNotEmpty) {
      return device.platformName;
    }

    try {
      final existingResult = _scanResults.firstWhere(
            (r) => r.device.remoteId.str == deviceId,
      );

      if (existingResult.advertisementData.advName.isNotEmpty) {
        return existingResult.advertisementData.advName;
      }
    } catch (e) {
      // Hiçbir şey yapma
    }

    return deviceId.length > 8 ? '${deviceId.substring(0, 8)}...' : deviceId;
  }

  // Bağlantı Kurma
  Future<void> connectToDevice(
      blue_plus.BluetoothDevice device, {
        int maxRetries = 3,
      }) async {
    if (_isConnecting) {
      print('⏳ Bağlantı zaten devam ediyor');
      return;
    }

    if (_connectionLocked) {
      print('🔒 Bağlantı kilitli! Önce bağlantıyı kesin');
      return;
    }

    _isConnecting = true;
    _updateConnectionState(BluetoothServiceState.connecting);
    String deviceName = getDeviceDisplayName(device);

    int retryCount = 0;
    Exception? lastException;

    while (retryCount <= maxRetries) {
      try {
        if (retryCount > 0) {
          print('🔄 Tekrar deneme $retryCount/$maxRetries: $deviceName');
          // Exponential backoff: 1s, 2s, 4s
          int delayMs = (1000 * (1 << (retryCount - 1))).clamp(1000, 4000);
          await Future.delayed(Duration(milliseconds: delayMs));
        } else {
          print('🔗 $deviceName cihazına bağlanılıyor...');
        }

        // Önce mevcut bağlantıyı kes
        try {
          await device.disconnect();
          await Future.delayed(Duration(milliseconds: 1000)); // Daha uzun bekle
        } catch (e) {
          print('⚠️ Disconnect hatası (göz ardı ediliyor): $e');
          await Future.delayed(Duration(milliseconds: 1000));
        }

        // Bluetooth adapter durumunu kontrol et
        final adapterState = await blue_plus.FlutterBluePlus.adapterState.first;
        if (adapterState != blue_plus.BluetoothAdapterState.on) {
          throw Exception('Bluetooth adaptörü kapalı');
        }

        // Bağlantı durumunu kontrol et
        final currentConnectionState = await device.connectionState.first;
        if (currentConnectionState ==
            blue_plus.BluetoothConnectionState.connected) {
          print('✅ Cihaz zaten bağlı');
          _connectedDevice = device;
          _connectionLocked = true;
          _isConnecting = false;
          _updateConnectionState(BluetoothServiceState.connected);
          _stopScan();
          _monitorConnectionState(device);
          return;
        }

        // Connect with timeout
        await device
            .connect(
          autoConnect: false,
          timeout: Duration(seconds: 15), // 15 saniye timeout
        )
            .timeout(
          Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException(
              'Bağlantı zaman aşımına uğradı',
              Duration(seconds: 20),
            );
          },
        );

        // Bağlantı başarılı olup olmadığını kontrol et
        await Future.delayed(Duration(milliseconds: 1000));
        final connectionState = await device.connectionState.first;

        if (connectionState != blue_plus.BluetoothConnectionState.connected) {
          throw Exception('Bağlantı kurulamadı. Durum: $connectionState');
        }

        // Servisleri keşfet
        await discoverServicesAfterConnection(device);

        // Başarılı
        _connectedDevice = device;
        _connectionLocked = true;
        _isConnecting = false;
        _updateConnectionState(BluetoothServiceState.connected);

        if (!_pairedDevicesList.any((d) => d.remoteId == device.remoteId)) {
          _pairedDevicesList.add(device);
          _devicesController.add(_pairedDevicesList);
        }

        _stopScan();
        _monitorConnectionState(device);

        print('✅ Bağlandı: $deviceName');
        return; // Başarılı, çık
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        String errorString = e.toString();
        bool isError133 =
            errorString.contains('133') ||
                errorString.contains('ANDROID_SPECIFIC_ERROR') ||
                errorString.contains('GATT');

        print('❌ Deneme ${retryCount + 1} başarısız: $deviceName - $e');

        // Error 133 için daha fazla bekleme süresi ekle
        if (isError133 && retryCount < maxRetries) {
          print('⚠️ Error 133 tespit edildi, ek bekleme...');
          await Future.delayed(Duration(seconds: 2));
        }

        // Son deneme değilse tekrar dene
        if (retryCount < maxRetries) {
          retryCount++;
          // Bağlantıyı temizle
          try {
            await device.disconnect();
            await Future.delayed(Duration(milliseconds: 1000));
          } catch (_) {}
          continue;
        } else {
          // Tüm denemeler başarısız
          break;
        }
      }
    }

    // Tüm denemeler başarısız oldu
    _isConnecting = false;
    _updateConnectionState(BluetoothServiceState.error);

    try {
      await device.disconnect();
    } catch (_) {}

    if (lastException != null) {
      throw lastException;
    } else {
      throw Exception('Bağlantı kurulamadı (${maxRetries + 1} deneme)');
    }
  }

  // Hizmetleri Keşfet
  Future<void> discoverServicesAfterConnection(
      blue_plus.BluetoothDevice device,
      ) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      await device.discoverServices();
    } catch (e) {
      print('⚠️ Hizmet keşfi hatası: $e');
    }
  }

  // Bağlantı Durumunu İzle
  void _monitorConnectionState(blue_plus.BluetoothDevice device) {
    _connectionSubscription?.cancel();

    _connectionSubscription = device.connectionState.listen((state) {
      if (state == blue_plus.BluetoothConnectionState.disconnected) {
        print('❌ Bağlantı koptu');
        _handleDisconnection();
      }
    });
  }

  // Bağlantı Kontrolü
  Future<bool> isConnectedToDevice() async {
    if (_connectedDevice == null) {
      return false;
    }

    try {
      List<blue_plus.BluetoothDevice> connectedDevices =
      await blue_plus.FlutterBluePlus.connectedDevices;

      bool isStillConnected = connectedDevices.any(
            (d) => d.remoteId == _connectedDevice!.remoteId,
      );

      if (!isStillConnected) {
        _handleDisconnection();
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Bağlantı kontrol hatası: $e');
      return false;
    }
  }

  // Bağlantı Kesme
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        String deviceName = getDeviceDisplayName(_connectedDevice!);
        await _connectedDevice!.disconnect();
        print('✅ Bağlantı kesildi: $deviceName');
      } catch (e) {
        print('❌ Bağlantı kesme hatası: $e');
      }
    }
    _handleDisconnection();
  }

  void _handleDisconnection() {
    _connectedDevice = null;
    _connectionLocked = false;
    _isConnecting = false;
    _connectionSubscription?.cancel();

    _updateConnectionState(BluetoothServiceState.disconnected);

    if (_bluetoothState == blue_plus.BluetoothAdapterState.on) {
      _startContinuousScanning();
    }
  }

  void _updateConnectionState(BluetoothServiceState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  // Cleanup
  void dispose() {
    _continuousScanTimer?.cancel();
    _connectionSubscription?.cancel();
    _scanSubscription?.cancel();
    _bluetoothStateController.close();
    _connectionStateController.close();
    _devicesController.close();
    _scanResultsController.close();
  }

  // deneme fonksiyonları

  Future<void> connectToCsServer(String deviceAddress) async {
    bluetooth_serial.BluetoothConnection connection;

    try {
      // Cihaza bağlan
      connection = await bluetooth_serial.BluetoothConnection.toAddress
        (deviceAddress);
      print('Bağlandı: $deviceAddress');

      //String jsonData = '{"type":"isimlik_add","title":"Prof Doc","name":"em'
    //'re uzun","togle":"false","is_active":"true","time":"00:00:00"}';

      //connection.output.add(utf8.encode(jsonData + "\r\n"));
      //await connection.output.allSent;


      // Gelen veriyi dinle (C# ReadLine() ile uyumlu)
      connection.input?.listen((Uint8List data) {
        String message = String.fromCharCodes(data).trim();
        print("Gelen mesaj: $message");
      }).onDone(() {
        print('Bağlantı sonlandı');
      });

    } catch (e) {
      print('Bağlantı Hatası: $e');
    }
  }



  Future<void> getPairedDevices() async {
    // Bluetooth’un açık olduğundan emin ol
    BluetoothState state = await FlutterBluetoothSerial.instance.state;
    if (state != BluetoothState.STATE_ON) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }

    // Eşleşmiş cihazları al
    List<BluetoothDevice> devices =
    await FlutterBluetoothSerial.instance.getBondedDevices();

    for (var d in devices) {
      print("Cihaz: ${d.name} - MAC: ${d.address}");
    }
  }






}
