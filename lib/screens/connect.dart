import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue_plus;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as bluetooth_serial;
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../bluetooth_provider.dart';
import '../language.dart';
import '../image.dart';

class ConnectPage extends StatefulWidget {
  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  blue_plus.BluetoothAdapterState _bluetoothState = blue_plus.BluetoothAdapterState.unknown;
  List<blue_plus.ScanResult> _scanResults = [];
  List<blue_plus.BluetoothDevice> _pairedDevicesList = [];
  List<bluetooth_serial.BluetoothDevice> _bondedDevicesList = [];
  blue_plus.BluetoothDevice? _selectedDevice;
  bool _isScanning = false;
  StreamSubscription<List<blue_plus.ScanResult>>? _scanSubscription;
  Map<String, int?> _rssiValues = {};
  Map<String, DateTime> _lastSeenTimes = {};
  Map<String, String> _deviceNamesCache = {};
  Timer? _rssiUpdateTimer;
  Timer? _continuousScanTimer;
  Timer? _pairedDevicesScanTimer;
  Timer? _autoConnectTimer;

  final ScrollController _pairedScrollController = ScrollController();
  final ScrollController _nearbyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool granted = await _requestPermissions();
      if (granted) {
        _initBluetooth();
        _startRSSIUpdateTimer();
        _startContinuousScanning();
        _startPairedDevicesScanning();
        _startAutoConnect();
        _getBondedDevices();
      } else {
        _showPermissionDialog();
      }
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _rssiUpdateTimer?.cancel();
    _continuousScanTimer?.cancel();
    _pairedDevicesScanTimer?.cancel();
    _autoConnectTimer?.cancel();
    _pairedScrollController.dispose();
    _nearbyScrollController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    }
    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('İzin Gerekli'),
        content: Text('Bluetooth ve konum izinleri verilmelidir. Lütfen izinleri açın.'),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text('Ayarlar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _initBluetooth() async {
    blue_plus.FlutterBluePlus.adapterState.listen((state) async {
      if (!mounted) return;
      setState(() => _bluetoothState = state);

      if (state == blue_plus.BluetoothAdapterState.on) {
        await _getPairedDevices();
        await _getBondedDevices();
        if (!_isScanning) _startScan();
      } else {
        _stopScan();
        _showBluetoothDialog();
      }
    });

    final initialState = await blue_plus.FlutterBluePlus.adapterState
        .firstWhere((s) => s != blue_plus.BluetoothAdapterState.unknown);
    if (mounted) setState(() => _bluetoothState = initialState);

    if (_bluetoothState == blue_plus.BluetoothAdapterState.on) {
      await _getPairedDevices();
      await _getBondedDevices();
    } else {
      _showBluetoothDialog();
    }
  }

  void _showBluetoothDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Bluetooth Kapalı'),
        content: Text('Lütfen cihazınızın Bluetooth\'unu açın.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _startPairedDevicesScanning() {
    _pairedDevicesScanTimer?.cancel();
    _pairedDevicesScanTimer = Timer.periodic(Duration(seconds: 4), (_) async {
      if (_bluetoothState != blue_plus.BluetoothAdapterState.on) return;

      await _getBondedDevices();
      await _getPairedDevices();
    });
  }

  void _startAutoConnect() {
    _autoConnectTimer?.cancel();
    _autoConnectTimer = Timer.periodic(Duration(seconds: 4), (_) async {
      if (_bluetoothState != blue_plus.BluetoothAdapterState.on) return;

      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);

      if (bluetoothProvider.connectedDevice != null || bluetoothProvider.isConnecting) {
        return;
      }

      await _tryAutoConnectToPairedDevices();
    });
  }

  Future<void> _tryAutoConnectToPairedDevices() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);

    print('📡 Otomatik bağlantı taraması başlatıldı. Eşleşmiş cihaz sayısı: ${_pairedDevicesList.length}');

    for (blue_plus.BluetoothDevice device in _pairedDevicesList) {
      try {
        print('🔗 ${_getDeviceDisplayName(device)} cihazına bağlanılmaya çalışılıyor...');

        await device.connect(autoConnect: false, timeout: Duration(seconds: 3));

        bluetoothProvider.setConnectedDevice(device);
        setState(() => _selectedDevice = device);

        print('✅ Otomatik bağlantı başarılı: ${_getDeviceDisplayName(device)}');
        break;
      }
      catch (e) {
        print('❌ ${_getDeviceDisplayName(device)} cihazına otomatik bağlanılamadı: $e');
        continue;
      }
    }
  }

  Future<void> _getBondedDevices() async {
    try {
      List<bluetooth_serial.BluetoothDevice> bondedDevices = await bluetooth_serial.FlutterBluetoothSerial.instance.getBondedDevices();
      _bondedDevicesList = bondedDevices;

      for (var bondedDevice in _bondedDevicesList) {
        if (bondedDevice.name != null && bondedDevice.name!.isNotEmpty) {
          _deviceNamesCache[bondedDevice.address] = bondedDevice.name!;
        }
      }

      for (var serialDevice in _bondedDevicesList) {
        try {
          blue_plus.BluetoothDevice device = blue_plus.BluetoothDevice.fromId(serialDevice.address);

          if (!_pairedDevicesList.any((d) => d.remoteId.str == serialDevice.address)) {
            _pairedDevicesList.add(device);
          }
        } catch (e) {
          print('Eşleşmiş cihaz eklenirken hata: $e');
        }
      }

      setState(() {});
    } catch (e) {
      print('Eşleşmiş cihazlar alınamadı: $e');
    }
  }

  Future<void> _getPairedDevices() async {
    try {
      List<blue_plus.BluetoothDevice> connectedDevices = await blue_plus.FlutterBluePlus.connectedDevices;

      for (var device in connectedDevices) {
        if (!_pairedDevicesList.any((d) => d.remoteId == device.remoteId)) {
          _pairedDevicesList.add(device);
        }
      }

      for (var device in _pairedDevicesList) {
        _rssiValues.putIfAbsent(device.remoteId.str, () => null);
        _lastSeenTimes.putIfAbsent(device.remoteId.str, () => DateTime.now());
      }

      setState(() {});
    } catch (e) {
      print('Bağlı cihazlar alınamadı: $e');
    }
  }

  void _startContinuousScanning() {
    _continuousScanTimer?.cancel();
    _continuousScanTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
      if (_bluetoothState != blue_plus.BluetoothAdapterState.on || bluetoothProvider.isConnecting) return;

      if (!_isScanning) {
        _startScan();
        Future.delayed(Duration(seconds: 2), _stopScan);
      }
    });
  }

  void _startScan() {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    if (_isScanning || _bluetoothState != blue_plus.BluetoothAdapterState.on || bluetoothProvider.isConnecting) return;

    setState(() => _isScanning = true);
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
        _lastSeenTimes[result.device.remoteId.str] = DateTime.now();

        _updateDeviceNameFromSerial(result.device);
      }
      setState(() {});
    }, onError: (error) {
      print('Tarama hatası: $error');
      setState(() => _isScanning = false);
    });

    blue_plus.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  void _updateDeviceNameFromSerial(blue_plus.BluetoothDevice device) async {
    try {
      List<bluetooth_serial.BluetoothDevice> bondedDevices = await bluetooth_serial.FlutterBluetoothSerial.instance.getBondedDevices();

      bluetooth_serial.BluetoothDevice? bondedDevice = bondedDevices.firstWhere(
            (d) => d.address == device.remoteId.str,
        orElse: () => bluetooth_serial.BluetoothDevice(
            name: "",
            address: device.remoteId.str,
            type: bluetooth_serial.BluetoothDeviceType.unknown,
            isConnected: false
        ),
      );

      if (bondedDevice.name != null && bondedDevice.name!.isNotEmpty) {
        _deviceNamesCache[device.remoteId.str] = bondedDevice.name!;
        if (mounted) setState(() {});
      }
    }
    catch (e) {
      print('Cihaz ismi güncellenirken hata: $e');
    }
  }

  void _stopScan() {
    blue_plus.FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    setState(() => _isScanning = false);
  }

  void _startRSSIUpdateTimer() {
    _rssiUpdateTimer = Timer.periodic(Duration(seconds: 5), (_) {
      final now = DateTime.now();
      _lastSeenTimes.removeWhere((key, value) => now.difference(value).inMinutes > 2);
      _rssiValues.removeWhere((key, value) => !_lastSeenTimes.containsKey(key));
      if (mounted) setState(() {});
    });
  }

  String _getDeviceDisplayName(blue_plus.BluetoothDevice device) {
    String deviceId = device.remoteId.str;

    bluetooth_serial.BluetoothDevice? bondedDevice = _bondedDevicesList.firstWhere(
          (d) => d.address == deviceId,
      orElse: () => bluetooth_serial.BluetoothDevice(
          name: "",
          address: deviceId,
          type: bluetooth_serial.BluetoothDeviceType.unknown,
          isConnected: false
      ),
    );

    if (bondedDevice.name != null && bondedDevice.name!.isNotEmpty) {
      return bondedDevice.name!;
    }

    if (_deviceNamesCache.containsKey(deviceId)) {
      return _deviceNamesCache[deviceId]!;
    }

    blue_plus.ScanResult? scanResult = _scanResults.firstWhere(
          (r) => r.device.remoteId == device.remoteId,
      orElse: () => _createDefaultScanResult(device, null),
    );

    if (scanResult.advertisementData.advName.isNotEmpty) {
      return scanResult.advertisementData.advName;
    }

    if (device.platformName.isNotEmpty) {
      return device.platformName;
    }

    return device.remoteId.str;
  }

  Future<void> _connectToDevice(blue_plus.BluetoothDevice device) async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    if (bluetoothProvider.isConnecting || bluetoothProvider.connectedDevice != null) return;

    bluetoothProvider.setConnecting(true);
    _stopScan();

    try {
      print('${_getDeviceDisplayName(device)} cihazına bağlanılıyor...');

      await device.connect(autoConnect: false, timeout: Duration(seconds: 10));

      if (!_isDeviceBonded(device)) {
        print('Cihaz eşleştirilmemiş, eşleştirme yapılıyor...');
        await _pairAndConnectDevice(device);
      } else {
        bluetoothProvider.setConnectedDevice(device);
        setState(() => _selectedDevice = device);
      }

      if (!_pairedDevicesList.any((d) => d.remoteId == device.remoteId)) {
        _pairedDevicesList.add(device);
        setState(() {});
      }

      print('Bağlantı başarılı: ${_getDeviceDisplayName(device)}');

    } catch (e) {
      print('Bağlantı hatası: ${_getDeviceDisplayName(device)} -> $e');
      _showConnectionErrorDialog(_getDeviceDisplayName(device));
    } finally {
      bluetoothProvider.setConnecting(false);
      if (_bluetoothState == blue_plus.BluetoothAdapterState.on) _startScan();
    }
  }

  void _showConnectionErrorDialog(String deviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bağlantı Hatası'),
        content: Text('$deviceName cihazına bağlanılamadı. Lütfen cihazın açık olduğundan ve yakınınızda olduğundan emin olun.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  bool _isDeviceBonded(blue_plus.BluetoothDevice device) {
    return _bondedDevicesList.any((d) => d.address == device.remoteId.str);
  }

  Future<void> _pairAndConnectDevice(blue_plus.BluetoothDevice device) async {
    try {
      print('${_getDeviceDisplayName(device)} cihazı eşleştiriliyor...');

      bool? isPaired = await bluetooth_serial.FlutterBluetoothSerial.instance
          .bondDeviceAtAddress(device.remoteId.str);

      if (isPaired == true) {
        print('Cihaz başarıyla eşleştirildi: ${_getDeviceDisplayName(device)}');

        await _getBondedDevices();

        await device.connect(autoConnect: false, timeout: Duration(seconds: 5));

        final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
        bluetoothProvider.setConnectedDevice(device);
        setState(() => _selectedDevice = device);

        print('Eşleştirme ve bağlantı başarılı: ${_getDeviceDisplayName(device)}');
      } else {
        print('Cihaz eşleştirilemedi: ${_getDeviceDisplayName(device)}');
        throw Exception('Eşleştirme başarısız');
      }
    } catch (e) {
      print('Eşleştirme hatası: $e');
      rethrow;
    }
  }

  void _disconnect() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    if (bluetoothProvider.connectedDevice != null) {
      print('${_getDeviceDisplayName(bluetoothProvider.connectedDevice!)} cihazından bağlantı kesiliyor');
      await bluetoothProvider.disconnect();
    }
    setState(() => _selectedDevice = null);
    if (_bluetoothState == blue_plus.BluetoothAdapterState.on) _startScan();
  }

  int _getSignalStrength(int? rssi) {
    if (rssi == null) return 0;
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }

  Widget _buildSignalIndicator(int? rssi) {
    int level = _getSignalStrength(rssi);
    return Row(
      children: List.generate(4, (index) {
        return Container(
          width: 3,
          height: (index + 1) * 3.0,
          margin: EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: index < level ? _getSignalColor(level) : Colors.grey[300],
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Color _getSignalColor(int level) {
    switch (level) {
      case 4: return Colors.green;
      case 3: return Colors.lightGreen;
      case 2: return Colors.orange;
      case 1: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getDeviceIcon(blue_plus.BluetoothDevice device) {
    String deviceName = _getDeviceDisplayName(device).toLowerCase();
    if (deviceName.contains('speaker') || deviceName.contains('audio') || deviceName.contains('sound') || deviceName.contains('podium')) {
      return Icons.speaker;
    } else if (deviceName.contains('headphone') || deviceName.contains('earbuds')) {
      return Icons.headphones;
    } else if (deviceName.contains('phone')) {
      return Icons.phone_android;
    } else if (deviceName.contains('watch')) {
      return Icons.watch;
    } else if (deviceName.contains('tv')) {
      return Icons.tv;
    } else if (deviceName.contains('keyboard')) {
      return Icons.keyboard;
    } else if (deviceName.contains('mouse')) {
      return Icons.mouse;
    } else {
      return Icons.bluetooth;
    }
  }

  blue_plus.ScanResult _createDefaultScanResult(blue_plus.BluetoothDevice device, int? rssi) {
    return blue_plus.ScanResult(
      device: device,
      advertisementData: blue_plus.AdvertisementData(
        advName: "",
        appearance: 0,
        connectable: false,
        manufacturerData: {},
        serviceData: {},
        serviceUuids: [],
        txPowerLevel: null,
      ),
      rssi: rssi ?? -100,
      timeStamp: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);
    final bool isTablet = screenSize.width > 600;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Color(0xFFE0E0E0),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: double.infinity,
                  child: ImageWidget(activePage: "connect"),
                ),
                if (_bluetoothState != blue_plus.BluetoothAdapterState.on)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    color: Colors.red.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_disabled, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text('Bluetooth kapalı - Lütfen açın',
                            style: TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ),
                  ),
                Expanded(
                  child: isTablet
                      ? _buildTabletLayout(languageProvider, screenSize)
                      : _buildMobileLayout(languageProvider, screenSize),
                ),
                if (bluetoothProvider.isConnecting)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    color: Colors.blue.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            languageProvider.getTranslation('pairing_connecting'),
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _bluetoothState != blue_plus.BluetoothAdapterState.on ? null : () {
                      if (bluetoothProvider.connectedDevice != null) {
                        _disconnect();
                      } else if (_selectedDevice != null && !bluetoothProvider.isConnecting) {
                        _connectToDevice(_selectedDevice!);
                      }
                    },
                    icon: Icon(bluetoothProvider.connectedDevice != null ? Icons.link_off : Icons.bluetooth,
                        color: Colors.white, size: 22),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        bluetoothProvider.isConnecting
                            ? languageProvider.getTranslation('processing')
                            : bluetoothProvider.connectedDevice != null
                            ? languageProvider.getTranslation('disconnect')
                            : (_selectedDevice != null)
                            ? languageProvider.getTranslation('connect')
                            : languageProvider.getTranslation('select_device'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      backgroundColor: _getButtonColor(bluetoothProvider),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout(LanguageProvider languageProvider, Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: _buildCardSection(
              languageProvider.getTranslation('paired_podiums'),
              _pairedDevicesList,
              false,
              languageProvider,
              _pairedScrollController,
              maxHeight: screenSize.height * 0.35,
              isTablet: true,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            flex: 1,
            child: _buildCardSection(
              languageProvider.getTranslation('nearby_devices'),
              _scanResults.map((r) => r.device).toList(),
              true,
              languageProvider,
              _nearbyScrollController,
              maxHeight: screenSize.height * 0.35,
              isTablet: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(LanguageProvider languageProvider, Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: _buildCardSection(
              languageProvider.getTranslation('paired_podiums'),
              _pairedDevicesList,
              false,
              languageProvider,
              _pairedScrollController,
              maxHeight: screenSize.height * 0.35,
              isTablet: false,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            flex: 1,
            child: _buildCardSection(
              languageProvider.getTranslation('nearby_devices'),
              _scanResults.map((r) => r.device).toList(),
              true,
              languageProvider,
              _nearbyScrollController,
              maxHeight: screenSize.height * 0.35,
              isTablet: false,
            ),
          ),
        ],
      ),
    );
  }

  Color _getButtonColor(BluetoothProvider bluetoothProvider) {
    if (_bluetoothState != blue_plus.BluetoothAdapterState.on) return Colors.grey;
    if (bluetoothProvider.isConnecting) return Colors.grey;
    if (bluetoothProvider.connectedDevice != null) return Colors.red;
    if (_selectedDevice != null) return Color(0xFF00D2C8);
    return Colors.grey;
  }

  Widget _buildCardSection(String title, List<blue_plus.BluetoothDevice> devices, bool isNearby,
      LanguageProvider languageProvider, ScrollController scrollController,
      {double maxHeight = 200, required bool isTablet}) {
    bool isPaired = title == languageProvider.getTranslation('paired_podiums');
    Color headerColor = const Color(0xFF4DB6AC);
    Color headerTextColor = const Color(0xFF00695C);
    IconData titleIcon = isPaired ? Icons.bluetooth_connected : Icons.bluetooth_searching;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: headerColor, width: 1.5),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: isTablet ? 45 : 40,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(titleIcon, color: headerTextColor, size: isTablet ? 22 : 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                              color: headerTextColor,
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.bold
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isNearby)
                  IconButton(
                    onPressed: _isScanning ? null : _startScan,
                    icon: _isScanning
                        ? SizedBox(
                        width: isTablet ? 24 : 20,
                        height: isTablet ? 24 : 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(headerTextColor)
                        ))
                        : Icon(Icons.refresh, color: headerTextColor, size: isTablet ? 22 : 20),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                        width: isTablet ? 36 : 32,
                        height: isTablet ? 36 : 32
                    ),
                  )
                else
                  SizedBox(width: isTablet ? 36 : 32, height: isTablet ? 36 : 32),
              ],
            ),
          ),
          Expanded(
            child: devices.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isNearby ? Icons.bluetooth_disabled : Icons.bluetooth_searching,
                      size: isTablet ? 42 : 36, color: Colors.grey[400]),
                  SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isNearby ? languageProvider.getTranslation('no_devices_found') : languageProvider.getTranslation('no_paired_podiums'),
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isTablet ? 14 : 12
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
                : Scrollbar(
              thumbVisibility: true,
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: 4),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  blue_plus.BluetoothDevice device = devices[index];
                  final bluetoothProvider = Provider.of<BluetoothProvider>(context);
                  bool isConnected = bluetoothProvider.connectedDevice?.remoteId == device.remoteId;
                  int? rssi = _rssiValues[device.remoteId.str];

                  return InkWell(
                    onTap: bluetoothProvider.isConnecting ? null : () => setState(() => _selectedDevice = device),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: isTablet ? 10 : 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedDevice?.remoteId == device.remoteId ? Colors.green : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        color: _selectedDevice?.remoteId == device.remoteId ? Colors.green[50] : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(_getDeviceIcon(device),
                                    size: isTablet ? 18 : 16, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getDeviceDisplayName(device),
                                    style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                _buildSignalIndicator(rssi),
                              ],
                            ),
                          ),
                          if (isConnected)
                            Icon(Icons.check_circle, color: Colors.green, size: isTablet ? 18 : 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}