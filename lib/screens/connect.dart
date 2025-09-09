import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'footer.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../image.dart';
import '../bluetooth_provider.dart';

class ConnectPage extends StatefulWidget {
  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDiscoveryResult> _discoveryResults = [];
  List<BluetoothDevice> _pairedDevicesList = [];
  BluetoothDevice? _selectedDevice;
  bool _isScanning = false;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  Map<String, int?> _rssiValues = {};
  Map<String, DateTime> _lastSeenTimes = {};
  Timer? _backgroundCheckTimer;
  Timer? _rssiUpdateTimer;
  Timer? _autoConnectTimer;
  Timer? _continuousScanTimer;

  final ScrollController _pairedScrollController = ScrollController();
  final ScrollController _nearbyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _requestPermissions().then((_) {
      _initBluetooth();
      _startBackgroundCheck();
      _startRSSIUpdateTimer();
      _startAutoConnectTimer();
      _startContinuousScanning();
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _backgroundCheckTimer?.cancel();
    _rssiUpdateTimer?.cancel();
    _autoConnectTimer?.cancel();
    _continuousScanTimer?.cancel();
    _pairedScrollController.dispose();
    _nearbyScrollController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.location,
      Permission.bluetooth,
    ].request();
  }

  void _initBluetooth() async {
    _bluetoothState = await FlutterBluetoothSerial.instance.state;
    setState(() {});
    _getPairedDevices();

    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      setState(() => _bluetoothState = state);
      if (state == BluetoothState.STATE_ON) {
        _startDiscovery();
      } else {
        _stopDiscovery();
      }
    });
  }

  void _startContinuousScanning() {
    _continuousScanTimer?.cancel();
    _continuousScanTimer = Timer.periodic(Duration(seconds: 4), (timer) async {
      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
      if (_bluetoothState != BluetoothState.STATE_ON || bluetoothProvider.isConnecting) return;

      _startDiscovery();
      Future.delayed(Duration(seconds: 2), _stopDiscovery);

      if (_pairedDevicesList.isNotEmpty && bluetoothProvider.connectedDevice == null) {
        for (BluetoothDevice device in _pairedDevicesList) {
          // timeout ile sırayla bağlan
          print('Otomatik bağlanılıyor: ${device.name}');
          await _pairAndConnectToDevice(device);

          if (bluetoothProvider.connectedDevice != null) break;
        }
      }
    });
  }

  Future<void> _getPairedDevices() async {
    try {
      _pairedDevicesList = await FlutterBluetoothSerial.instance.getBondedDevices();
      for (var device in _pairedDevicesList) {
        _rssiValues.putIfAbsent(device.address, () => null);
        _lastSeenTimes.putIfAbsent(device.address, () => DateTime.now().subtract(Duration(minutes: 10)));
      }
      setState(() {});
    } catch (e) {
      print('Eşleşmiş cihazlar alınırken hata: $e');
    }
  }

  void _startDiscovery() {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    if (_isScanning || _bluetoothState != BluetoothState.STATE_ON || bluetoothProvider.isConnecting) return;

    setState(() => _isScanning = true);
    _discoveryResults.clear();

    _streamSubscription?.cancel();
    _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen(
          (result) {
        if (_pairedDevicesList.any((device) => device.address == result.device.address)) {
          _rssiValues[result.device.address] = result.rssi;
          _lastSeenTimes[result.device.address] = DateTime.now();
          setState(() {});
          return;
        }

        final index = _discoveryResults.indexWhere((r) => r.device.address == result.device.address);
        if (index >= 0) {
          _discoveryResults[index] = result;
        } else {
          _discoveryResults.add(result);
        }

        _rssiValues[result.device.address] = result.rssi;
        _lastSeenTimes[result.device.address] = DateTime.now();

        setState(() {});
      },
      onError: (error) {
        print('Discovery error: $error');
        setState(() => _isScanning = false);
      },
    );

    _streamSubscription!.onDone(() {
      setState(() => _isScanning = false);
    });
  }

  void _stopDiscovery() {
    _streamSubscription?.cancel();
    setState(() => _isScanning = false);
  }

  void _startBackgroundCheck() {
    _backgroundCheckTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
      if (_bluetoothState != BluetoothState.STATE_ON || bluetoothProvider.isConnecting) return;

      // RSSI değerlerini güncelle
      for (var device in _pairedDevicesList) {
        if (_rssiValues.containsKey(device.address)) {
          setState(() {});
        }
      }
    });
  }

  void _startAutoConnectTimer() {
    _autoConnectTimer = Timer.periodic(Duration(seconds: 15), (_) async {
      final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
      if (_bluetoothState != BluetoothState.STATE_ON || bluetoothProvider.isConnecting || bluetoothProvider.connectedDevice != null) return;

      if (_pairedDevicesList.isNotEmpty) {
        for (BluetoothDevice device in _pairedDevicesList) {
          print('Otomatik bağlantı deneniyor: ${device.name}');
          await _pairAndConnectToDevice(device);

          if (bluetoothProvider.connectedDevice != null) break;
        }
      }
    });
  }

  void _startRSSIUpdateTimer() {
    _rssiUpdateTimer = Timer.periodic(Duration(seconds: 5), (_) {
      final now = DateTime.now();
      _lastSeenTimes.removeWhere((key, value) =>
      now.difference(value).inMinutes > 2);

      _rssiValues.removeWhere((key, value) =>
      !_lastSeenTimes.containsKey(key));

      if (mounted) setState(() {});
    });
  }

  Future<void> _pairAndConnectToDevice(BluetoothDevice device) async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);

    if (bluetoothProvider.isConnecting) return;
    bluetoothProvider.setConnecting(true);
    _stopDiscovery();

    try {
      if (!_pairedDevicesList.any((d) => d.address == device.address)) {
        bool? bonded = await FlutterBluetoothSerial.instance
            .bondDeviceAtAddress(device.address)
            .timeout(Duration(seconds: 5), onTimeout: () => false);
        if (bonded != true) throw Exception('Eşleştirme başarısız');
        await _getPairedDevices();
      }

      if (bluetoothProvider.connection != null) {
        await bluetoothProvider.connection!.close();
      }

      BluetoothConnection connection = await BluetoothConnection
          .toAddress(device.address)
          .timeout(Duration(seconds: 8));

      bluetoothProvider.setConnection(connection, device);
      setState(() => _selectedDevice = device);

      connection.input?.listen((_) {}, onDone: () {
        bluetoothProvider.setConnection(null, null);
      }, onError: (_) {
        bluetoothProvider.setConnection(null, null);
      });
    } catch (e) {
      print('Bağlantı hatası: ${device.name} -> $e');
      bluetoothProvider.setConnection(null, null);
    }
    finally {
      bluetoothProvider.setConnecting(false);
      if (_bluetoothState == BluetoothState.STATE_ON) _startDiscovery();
    }
  }


  void _disconnect() async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    await bluetoothProvider.disconnect();
    setState(() => _selectedDevice = null);
    print('Bağlantı manuel olarak kesildi');

    if (_bluetoothState == BluetoothState.STATE_ON) {
      _startDiscovery();
    }
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

  String _getSignalText(int? rssi) {
    int level = _getSignalStrength(rssi);
    switch (level) {
      case 4: return 'Mükemmel';
      case 3: return 'İyi';
      case 2: return 'Orta';
      case 1: return 'Zayıf';
      default: return 'Bilinmiyor';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Color(0xFFE0E0E0),
          body: Column(
            children: [
              Container(
                height: screenSize.height * 0.15,
                width: double.infinity,
                margin: EdgeInsets.only(top: 0),
                child: ImageWidget(
                  fit: BoxFit.cover,
                  showBluetoothStatus: true,
                  connection: bluetoothProvider.connection,
                  connectedDevice: bluetoothProvider.connectedDevice,
                ),
              ),

              if (_bluetoothState != BluetoothState.STATE_ON)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  color: Colors.red.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth_disabled, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Bluetooth kapalı - Lütfen açın',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: SafeArea(
                  top: false,
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    children: [
                      _buildCardSection(
                        languageProvider.getTranslation('paired_podiums'),
                        _pairedDevicesList,
                        false,
                        languageProvider,
                        _pairedScrollController,
                        maxHeight: screenSize.height * 0.25,
                      ),
                      SizedBox(height: 13),
                      _buildCardSection(
                        languageProvider.getTranslation('nearby_devices'),
                        _discoveryResults.map((r) => r.device).toList(),
                        true,
                        languageProvider,
                        _nearbyScrollController,
                        maxHeight: screenSize.height * 0.25,
                      ),
                    ],
                  ),
                ),
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
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              SafeArea(
                top: false,
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _bluetoothState != BluetoothState.STATE_ON ? null : () {
                          if (bluetoothProvider.connectedDevice != null) {
                            _disconnect();
                            setState(() => _selectedDevice = null);
                          } else if (_selectedDevice != null && !bluetoothProvider.isConnecting) {
                            _pairAndConnectToDevice(_selectedDevice!);
                          }
                        },
                        icon: Icon(
                          bluetoothProvider.connectedDevice != null ? Icons.link_off : Icons.bluetooth,
                          color: Colors.white,
                          size: 22,
                        ),
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          backgroundColor: _bluetoothState != BluetoothState.STATE_ON
                              ? Colors.grey
                              : bluetoothProvider.isConnecting
                              ? Colors.grey
                              : bluetoothProvider.connectedDevice != null
                              ? Colors.red
                              : (_selectedDevice != null)
                              ? Color(0xFF546E7A)
                              : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    AppFooter(activeTab: "connection"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardSection(String title, List<BluetoothDevice> devices, bool isNearby,
      LanguageProvider languageProvider, ScrollController scrollController,
      {double maxHeight = 200}) {
    bool isPaired = title == languageProvider.getTranslation('paired_podiums');
    Color headerColor = const Color(0xFF4DB6AC);
    Color headerTextColor = const Color(0xFF00695C);
    IconData titleIcon = isPaired ? Icons.bluetooth_connected : Icons
        .bluetooth_searching;

    double iconSize = 20.0;
    double fontSize = 14.0;
    double headerHeight = 40.0;

    return Container(
      width: double.infinity,
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
            height: headerHeight,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(titleIcon, color: headerTextColor, size: iconSize),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: headerTextColor,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
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
                    onPressed: _isScanning ? null : _startDiscovery,
                    icon: _isScanning
                        ? SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            headerTextColor),
                      ),
                    )
                        : Icon(
                        Icons.refresh, color: headerTextColor, size: iconSize),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(width: 32, height: 32),
                  )
                else
                  SizedBox(width: 32, height: 32),
              ],
            ),
          ),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            child: devices.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isNearby ? Icons.bluetooth_disabled : Icons
                        .bluetooth_searching,
                    size: 36,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isNearby
                          ? languageProvider.getTranslation('no_devices_found')
                          : languageProvider.getTranslation(
                          'no_paired_podiums'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
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
                // boşluğu azalt
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  BluetoothDevice device = devices[index];
                  final bluetoothProvider = Provider.of<BluetoothProvider>(
                      context, listen: true);
                  bool isConnected = bluetoothProvider.connectedDevice
                      ?.address == device.address;
                  bool isSelected = _selectedDevice?.address == device.address;
                  int? rssi = _rssiValues[device.address];

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDevice = device);
                    },
                    child: _buildDeviceItem(
                      name: device.name ?? device.address,
                      icon: isPaired ? Icons.bluetooth_connected : Icons
                          .bluetooth,
                      iconColor: isConnected
                          ? Colors.green
                          : (isNearby ? Colors.grey[700]! : Colors.blue),
                      device: device,
                      isConnected: isConnected,
                      isSelected: isSelected,
                      rssi: rssi,
                      isPaired: isPaired,
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

  Widget _buildDeviceItem({
    required String name,
    required IconData icon,
    required Color iconColor,
    BluetoothDevice? device,
    bool isConnected = false,
    bool isSelected = false,
    int? rssi,
    bool isPaired = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected
              ? Colors.green
              : isSelected
              ? Colors.blue
              : Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 2),
                if (device != null && isConnected)
                  Text(
                    'Bağlı',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (rssi != null)
                  Text(
                    '${_getSignalText(rssi)} (${rssi} dBm)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  )
                else
                  Text(
                    'Sinyal alınamadı',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
          ),
          _buildSignalIndicator(rssi),
          SizedBox(width: 8),
          if (isConnected) Icon(Icons.link, color: Colors.green, size: 18),
        ],
      ),
    );
  }
}