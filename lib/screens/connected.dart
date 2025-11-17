import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue_plus;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as bluetooth_serial;
import 'package:permission_handler/permission_handler.dart';

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
  blue_plus.BluetoothAdapterState _bluetoothState = blue_plus.BluetoothAdapterState.unknown;
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

  // İsimlik listesi için yeni değişken
  List<Map<String, dynamic>> _isimlikList = [];

  // Stream controllers
  final _bluetoothStateController = StreamController<blue_plus.BluetoothAdapterState>.broadcast();
  final _connectionStateController = StreamController<BluetoothServiceState>.broadcast();
  final _devicesController = StreamController<List<blue_plus.BluetoothDevice>>.broadcast();
  final _scanResultsController = StreamController<List<blue_plus.ScanResult>>.broadcast();

  // Connection
  bluetooth_serial.BluetoothConnection? _connection;

  // Getters
  blue_plus.BluetoothAdapterState get bluetoothState => _bluetoothState;
  List<blue_plus.BluetoothDevice> get pairedDevices => _pairedDevicesList;
  List<blue_plus.BluetoothDevice> get nearbyDevices => _scanResults.map((r) => r.device).toList();
  BluetoothServiceState get connectionState => _connectionState;
  blue_plus.BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnecting => _isConnecting;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectedDevice != null && !_isConnecting;
  Map<String, int?> get rssiValues => _rssiValues;
  List<Map<String, dynamic>> get isimlikList => _isimlikList;

  List<String> get connectedDevicesMacAddresses {
    return _pairedDevicesList
        .where((device) => device.isConnected)
        .map((device) => device.remoteId.str)
        .toList();
  }
  static String? _connectedDeviceMacAddress;

  static String? get connectedDeviceMacAddress => _connectedDeviceMacAddress;

  static set connectedDeviceMacAddress(String? macAddress) {
    _connectedDeviceMacAddress = macAddress;
  }

  // Streams
  Stream<blue_plus.BluetoothAdapterState> get bluetoothStateStream => _bluetoothStateController.stream;
  Stream<BluetoothServiceState> get connectionStateStream => _connectionStateController.stream;
  Stream<List<blue_plus.BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<List<blue_plus.ScanResult>> get scanResultsStream => _scanResultsController.stream;

  StreamSubscription<List<blue_plus.ScanResult>>? _scanSubscription;
  StreamSubscription<blue_plus.BluetoothConnectionState>? _connectionSubscription;
  Timer? _continuousScanTimer;

  Future<bool> requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
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
      List<bluetooth_serial.BluetoothDevice> bondedDevices = await bluetooth_serial.FlutterBluetoothSerial.instance.getBondedDevices();

      _bondedDevicesList = bondedDevices;

      for (var bondedDevice in _bondedDevicesList) {
        try {
          blue_plus.BluetoothDevice device = blue_plus.BluetoothDevice.fromId(bondedDevice.address);

          if (!_pairedDevicesList.any((d) => d.remoteId.str == bondedDevice.address)) {
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
      List<blue_plus.BluetoothDevice> connectedDevices = await blue_plus.FlutterBluePlus.connectedDevices;

      for (var device in connectedDevices) {
        if (!_pairedDevicesList.any((d) => d.remoteId == device.remoteId)) {
          _pairedDevicesList.add(device);
        }

        String deviceId = device.remoteId.str;
        if (device.platformName.isNotEmpty && !_deviceNamesCache.containsKey(deviceId)) {
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
      if (_bluetoothState != blue_plus.BluetoothAdapterState.on || _isConnecting) return;

      if (!_isScanning) {
        startScan();
        Future.delayed(Duration(seconds: 10), _stopScan);
      }
    });
  }

  // Tarama Sistemi
  void startScan() {
    if (_isScanning || _bluetoothState != blue_plus.BluetoothAdapterState.on || _isConnecting) {
      return;
    }

    _isScanning = true;
    _scanResults.clear();

    _scanSubscription?.cancel();
    _scanSubscription = blue_plus.FlutterBluePlus.scanResults.listen((results) {
      for (blue_plus.ScanResult result in results) {
        final index = _scanResults.indexWhere((r) => r.device.remoteId == result.device.remoteId);
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
    }, onError: (error) {
      print('❌ Tarama hatası: $error');
      _isScanning = false;
    });

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
      final existingResult = _scanResults.firstWhere((r) => r.device.remoteId.str == deviceId);
      if (existingResult.advertisementData.advName.isNotEmpty) {
        return existingResult.advertisementData.advName;
      }
    } catch (e) {
      // Hiçbir şey yapma
    }

    return deviceId.length > 8 ? '${deviceId.substring(0, 8)}...' : deviceId;
  }

  // Bağlantı Kurma
  Future<void> connectToDevice(blue_plus.BluetoothDevice device, {int maxRetries = 3}) async {
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
          int delayMs = (1000 * (1 << (retryCount - 1))).clamp(1000, 4000);
          await Future.delayed(Duration(milliseconds: delayMs));
        } else {
          print('🔗 $deviceName cihazına bağlanılıyor...');
        }

        // Önce mevcut bağlantıyı kes
        try {
          await device.disconnect();
          await Future.delayed(Duration(milliseconds: 1000));
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
        if (currentConnectionState == blue_plus.BluetoothConnectionState.connected) {
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
        await device.connect(autoConnect: false, timeout: Duration(seconds: 15)).timeout(Duration(seconds: 20), onTimeout: () {
          throw TimeoutException('Bağlantı zaman aşımına uğradı', Duration(seconds: 20));
        });

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
        return;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        String errorString = e.toString();
        bool isError133 = errorString.contains('133') || errorString.contains('ANDROID_SPECIFIC_ERROR') || errorString.contains('GATT');

        print('❌ Deneme ${retryCount + 1} başarısız: $deviceName - $e');

        if (isError133 && retryCount < maxRetries) {
          print('⚠️ Error 133 tespit edildi, ek bekleme...');
          await Future.delayed(Duration(seconds: 2));
        }

        if (retryCount < maxRetries) {
          retryCount++;
          try {
            await device.disconnect();
            await Future.delayed(Duration(milliseconds: 1000));
          } catch (_) {}
          continue;
        } else {
          break;
        }
      }
    }

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
  Future<void> discoverServicesAfterConnection(blue_plus.BluetoothDevice device) async {
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
      List<blue_plus.BluetoothDevice> connectedDevices = await blue_plus.FlutterBluePlus.connectedDevices;
      bool isStillConnected = connectedDevices.any((d) => d.remoteId == _connectedDevice!.remoteId);

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
    _connection?.dispose();
    _connection = null;

    _updateConnectionState(BluetoothServiceState.disconnected);

    if (_bluetoothState == blue_plus.BluetoothAdapterState.on) {
      _startContinuousScanning();
    }
  }

  void _updateConnectionState(BluetoothServiceState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  Future<void> connectToCsServer(String address) async {
    while (true) {
      try {
        await _connection?.close();
        _connection = null;

        _connection = await bluetooth_serial.BluetoothConnection.toAddress(address);

        print('Serial bağlantı kuruldu: $address');

        _connection!.input!.listen((Uint8List data) {
          String message = String.fromCharCodes(data).trim();
          print('📨 Gelen veri: $message');
          _handleIncomingData(message);
        }).onDone(() async {
          print('⚠️ Bağlantı kesildi! Tekrar bağlanıyor...');
          _connection = null;
          await Future.delayed(Duration(seconds: 1));
        });

        break;
      } catch (e) {
        print("❌ Bağlantı hatası: $e");
        print("⏳ 2 saniye sonra yeniden denenecek...");
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  void _handleIncomingData(String message) {
    try {
      // Backslash'ları düzelt: tek \ yerine \\ yap
      String correctedMessage = message.replaceAll(r'\', r'\\');

      Map<String, dynamic> jsonData = jsonDecode(correctedMessage);
      print('📊 JSON verisi alındı: $jsonData');

      // Path'i kontrol et ve kaydet
      if (jsonData.containsKey('path')) {
        receivedVideoPath = jsonData['path'];
        print('✅ Path kaydedildi: $receivedVideoPath');
      }

      // Status kontrolü
      if (jsonData['status'] == 'ok') {
        print('✅ İşlem başarılı');
      }

    } catch (e) {
      print('❌ JSON parse hatası: $e');

      try {
        RegExp pathRegex = RegExp(r'"path":"([^"]+)"');
        Match? match = pathRegex.firstMatch(message);
        if (match != null) {
          receivedVideoPath = match.group(1);
          print('✅ Path regex ile alındı: $receivedVideoPath');
        }
      } catch (regexError) {
        print('❌ Regex hatası: $regexError');
      }
    }
  }


  Future<void> sendDataToDevice(String macAddress, Map<String, dynamic> data) async {
    try {
      await connectToCsServer(connectedDeviceMacAddress!);

      String jsonData = jsonEncode(data);
      _connection!.output.add(utf8.encode(jsonData + "\r\n"));
      await _connection!.output.allSent;
      print('Veri başarıyla gönderildi: $jsonData');
    }
    catch (e) {
      print('Veri gönderme hatası: $e');
      _connection = null;
      throw e;
    }
  }

  Future<void> isimlikAdd({
    required String name,
    required String title,
    required bool togle,
    required bool isActive,
    required String time,
  }) async {
    try {
      Map<String, dynamic> data = {
        "type": "isimlik_add",
        "title": title.trim(),
        "name": name.trim(),
        "togle": togle,
        "is_active": isActive,
        "time": time.trim()
      };

      await sendDataToDevice(connectedDeviceMacAddress!, data);
    }
    catch (e) {
      print(e);
      rethrow;
    }
  }


  Future<void> videosend({
    required String size,
    required String name,
    required String videoPath,
  }) async {
    try {
      if (_connection == null || !_connection!.isConnected) {
        throw Exception("❌ Bağlantı yok. Video gönderilemez.");
      }
      File videoFile = File(videoPath);
      Uint8List fileBytes = await videoFile.readAsBytes();
      int totalBytes = fileBytes.length;
      // Video metadata'yı gönder
      Map<String, dynamic> data = {
        "type": "video",
        "size": totalBytes,
        "name": name
      };
      await sendDataToDevice(connectedDeviceMacAddress!, data);
      print("📦 Video bilgileri gönderildi: $data");


      if (!videoFile.existsSync()) {
        throw Exception("❌ Video dosyası bulunamadı: $videoPath");
      }


      int offset = 0;
      int chunkSize = 4096; // 4KB chunk

      print("📦 Video gönderimi başlıyor. Toplam boyut: $totalBytes bytes");

      while (offset < totalBytes) {
        int bytesToSend = (offset + chunkSize > totalBytes)
            ? totalBytes - offset
            : chunkSize;

        Uint8List chunk = fileBytes.sublist(offset, offset + bytesToSend);
       if(_connection==null){
         connectToCsServer(connectedDeviceMacAddress!);
       }
        _connection!.output.add(chunk);
        await _connection!.output.allSent;

        offset += bytesToSend;

        double percent = offset / totalBytes * 100;
        print('\r📦 Gönderiliyor... %${percent.toStringAsFixed(1)}');
      }

      print("\n✅ Video gönderildi: $name");

      // Video gönderiminden sonra gelen mesajları dinle
      StreamSubscription<Uint8List>? subscription;
      subscription = _connection!.input!.listen((Uint8List data) {
        String message = String.fromCharCodes(data).trim();
        print('📨 Gelen mesaj: $message');

        // İlk mesaj alındıktan sonra kapat
        subscription?.cancel();
      });
      _connection!.close();


    } catch (e, stackTrace) {
      print("❌ Video gönderme hatası: $e");
      print("StackTrace:\n$stackTrace");
      rethrow;
    }
  }

  String? receivedVideoPath;

  Future<void> bilgiAdd({
    required String meeting_title,
    required String start_hour,
    required bool end_hour,
    required bool path,
    required bool is_active,
    required bool button_status,
  }) async {
    try {
      Map<String, dynamic> data = {
        "type":"bilgi_add",
        "meeting_title" : "Deneme",
        "start_hour" :"05:00:00",
        "end_hour" : "06:00:00",
        "path" : "C:\\Users\\uzun3\\Desktop\\Kürsü\\ARNAVUTKÖY BELEDİYESİ LOGO ANİMASYONU 1440 x 1280.mp4",
        "is_active" : "false",
        "button_status" :"true"
      };

      await sendDataToDevice(connectedDeviceMacAddress!, data);
      print("ekledi");
    }
    catch (e) {
      print("hata $e");
      rethrow;
    }
  }

  // Cleanup
  void dispose() {
    _continuousScanTimer?.cancel();
    _connectionSubscription?.cancel();
    _scanSubscription?.cancel();
    _connection?.dispose();

    _bluetoothStateController.close();
    _connectionStateController.close();
    _devicesController.close();
    _scanResultsController.close();
  }
}

// Bluetooth Bağlantı Sayfası
class BluetoothConnectionPage extends StatefulWidget {
  @override
  _BluetoothConnectionPageState createState() => _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  final BluetoothService _bluetoothService = BluetoothService();
  List<blue_plus.BluetoothDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _bluetoothService.initializeBluetooth();
    _setupListeners();
  }

  void _setupListeners() {
    _bluetoothService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices;
        });
      }
    });

    _bluetoothService.scanResultsStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    _bluetoothService.bluetoothStateStream.listen((state) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Cihazları'),
        backgroundColor: Color(0xFF1D7269),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.search),
            onPressed: _toggleScan,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<blue_plus.BluetoothAdapterState>(
      stream: _bluetoothService.bluetoothStateStream,
      builder: (context, snapshot) {
        final bluetoothState = snapshot.data ?? blue_plus.BluetoothAdapterState.unknown;

        if (bluetoothState != blue_plus.BluetoothAdapterState.on) {
          return _buildBluetoothOff();
        }

        return Column(
          children: [
            _buildConnectionStatus(),
            Expanded(
              child: _buildDevicesList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBluetoothOff() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Bluetooth Kapalı',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Bluetooth\'u açarak cihazları görebilirsiniz'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _bluetoothService.initializeBluetooth();
            },
            child: Text('Bluetooth\'u Aç'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return StreamBuilder<BluetoothServiceState>(
      stream: _bluetoothService.connectionStateStream,
      builder: (context, snapshot) {
        final connectionState = snapshot.data ?? BluetoothServiceState.disconnected;

        Color backgroundColor;
        String statusText;

        switch (connectionState) {
          case BluetoothServiceState.connected:
            backgroundColor = Colors.green;
            statusText = 'Bağlı';
            break;
          case BluetoothServiceState.connecting:
            backgroundColor = Colors.orange;
            statusText = 'Bağlanıyor...';
            break;
          case BluetoothServiceState.weakSignal:
            backgroundColor = Colors.yellow;
            statusText = 'Zayıf Sinyal';
            break;
          case BluetoothServiceState.error:
            backgroundColor = Colors.red;
            statusText = 'Hata';
            break;
          default:
            backgroundColor = Colors.grey;
            statusText = 'Bağlı Değil';
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          color: backgroundColor.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                _getConnectionIcon(connectionState),
                color: backgroundColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: backgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_bluetoothService.connectedDevice != null)
                Text(
                  _bluetoothService.getDeviceDisplayName(_bluetoothService.connectedDevice!),
                  style: TextStyle(color: backgroundColor),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getConnectionIcon(BluetoothServiceState state) {
    switch (state) {
      case BluetoothServiceState.connected:
        return Icons.bluetooth_connected;
      case BluetoothServiceState.connecting:
        return Icons.bluetooth_searching;
      case BluetoothServiceState.weakSignal:
        return Icons.signal_wifi_statusbar_connected_no_internet_4;
      case BluetoothServiceState.error:
        return Icons.error;
      default:
        return Icons.bluetooth_disabled;
    }
  }

  Widget _buildDevicesList() {
    if (_devices.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Cihaz bulunamadı'),
            SizedBox(height: 8),
            Text('Tarama yapmak için arama butonuna basın'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isConnected = device.isConnected;
        final rssi = _bluetoothService.rssiValues[device.remoteId.str];

        return _buildDeviceTile(device, isConnected, rssi);
      },
    );
  }

  Widget _buildDeviceTile(blue_plus.BluetoothDevice device, bool isConnected, int? rssi) {
    return ListTile(
      leading: Icon(
        isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
        color: isConnected ? Colors.green : Colors.grey,
      ),
      title: Text(_bluetoothService.getDeviceDisplayName(device)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(device.remoteId.str),
          if (rssi != null) Text('Sinyal: ${rssi}dBm'),
        ],
      ),
      trailing: _isConnecting
          ? CircularProgressIndicator()
          : ElevatedButton(
        onPressed: () => _handleDeviceConnection(device, isConnected),
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? Colors.red : Colors.green,
        ),
        child: Text(
          isConnected ? 'Bağlantıyı Kes' : 'Bağlan',
          style: TextStyle(color: Colors.white),
        ),
      ),
      onTap: () => _showDeviceDetails(device),
    );
  }

  void _handleDeviceConnection(blue_plus.BluetoothDevice device, bool isConnected) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      if (isConnected) {
        await _bluetoothService.disconnect();
      } else {
        await _bluetoothService.connectToDevice(device);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hata: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  void _showDeviceDetails(blue_plus.BluetoothDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cihaz Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('İsim: ${_bluetoothService.getDeviceDisplayName(device)}'),
            Text('MAC: ${device.remoteId.str}'),
            Text('Bağlı: ${device.isConnected ? 'Evet' : 'Hayır'}'),
            if (_bluetoothService.rssiValues[device.remoteId.str] != null)
              Text('Sinyal: ${_bluetoothService.rssiValues[device.remoteId.str]}dBm'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _toggleScan() {
    if (_isScanning) {
      _bluetoothService._stopScan();
      setState(() {
        _isScanning = false;
      });
    } else {
      _bluetoothService.startScan();
      setState(() {
        _isScanning = true;
      });

      // 10 saniye sonra taramayı durdur
      Future.delayed(Duration(seconds: 10), () {
        if (mounted && _isScanning) {
          _bluetoothService._stopScan();
          setState(() {
            _isScanning = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }
}