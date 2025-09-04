import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'footer.dart';
import 'package:provider/provider.dart';
import '../language.dart';

class ConnectPage extends StatefulWidget {
  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> _devicesList = [];
  List<BluetoothDevice> _pairedDevicesList = [];
  BluetoothConnection? _connection;
  bool _isConnecting = false;
  bool _isScanning = false;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _requestPermissions().then((_) => _initBluetooth());
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _connection?.dispose();
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
    try {
      BluetoothState state = await FlutterBluetoothSerial.instance.state;
      setState(() => _bluetoothState = state);
      _getPairedDevices();
      _startDiscovery();

      FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
        setState(() => _bluetoothState = state);
        _getPairedDevices();
        _startDiscovery();
      });
    } catch (_) {}
  }

  Future<void> _getPairedDevices() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() => _pairedDevicesList = devices);
    } catch (_) {}
  }

  void _startDiscovery() {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _devicesList.clear();
    });

    _streamSubscription?.cancel();
    _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      if (_pairedDevicesList.any((d) => d.address == r.device.address)) return;

      final existingIndex = _devicesList.indexWhere((d) => d.address == r.device.address);
      if (existingIndex >= 0) {
        _devicesList[existingIndex] = r.device;
      } else {
        _devicesList.add(r.device);
      }
      if (mounted) setState(() {});
    });

    _streamSubscription!.onDone(() {
      if (mounted) setState(() => _isScanning = false);
    });

    Timer(Duration(seconds: 30), () {
      if (_isScanning) _stopDiscovery();
    });
  }

  void _stopDiscovery() {
    _streamSubscription?.cancel();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _pairAndConnectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);
    _stopDiscovery();

    try {
      bool alreadyPaired = _pairedDevicesList.any((d) => d.address == device.address);

      if (!alreadyPaired) {
        bool? isPaired = await FlutterBluetoothSerial.instance.bondDeviceAtAddress(device.address);
        if (isPaired != true) throw Exception("Eşleştirme başarısız");

        await _getPairedDevices();
        setState(() {
          _devicesList.removeWhere((d) => d.address == device.address);
        });
      }

      BluetoothDevice deviceToConnect = _pairedDevicesList.firstWhere(
              (d) => d.address == device.address,
          orElse: () => device
      );

      if (_connection != null) {
        await _connection!.close();
        _connection = null;
      }

      BluetoothConnection connection = await BluetoothConnection.toAddress(deviceToConnect.address);

      setState(() {
        _connection = connection;
        _connectedDevice = deviceToConnect;
        _selectedDevice = deviceToConnect;
        _isConnecting = false;
      });

      _connection!.input!.listen(
            (data) {},
        onDone: () {
          if (mounted) {
            setState(() {
              _connection = null;
              _connectedDevice = null;
            });
          }
        },
        onError: (error) {
          print('Bağlantı hatası: $error');
          if (mounted) {
            setState(() {
              _connection = null;
              _connectedDevice = null;
            });
          }
        },
      );

      print('Bağlantı başarılı: ${deviceToConnect.name ?? deviceToConnect.address}');
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connection = null;
        _connectedDevice = null;
      });
      print('Bağlantı hatası: ${e.toString()}');
    }
  }

  void _disconnect() async {
    try {
      await _connection?.close();
      setState(() {
        _connection = null;
        _connectedDevice = null;
      });
      print('Bağlantı kesildi');
    } catch (e) {
      print('Bağlantı kesme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Color(0xFFE0E0E0),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    children: [
                      _buildCardSection(
                        languageProvider.getTranslation('paired_podiums'),
                        _pairedDevicesList,
                        false,
                        languageProvider,
                        maxHeight: screenSize.height * 0.20,
                      ),
                      SizedBox(height: 16),
                      _buildCardSection(
                        languageProvider.getTranslation('nearby_devices'),
                        _devicesList,
                        true,
                        languageProvider,
                        maxHeight: screenSize.height * 0.20,
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                if (_isConnecting)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
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
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_connectedDevice != null) {
                        _disconnect();
                        setState(() => _selectedDevice = null);
                      } else if (_selectedDevice != null && !_isConnecting) {
                        _pairAndConnectToDevice(_selectedDevice!);
                      }
                    },
                    icon: Icon(
                      _connectedDevice != null ? Icons.link_off : Icons.bluetooth,
                      color: Colors.white,
                      size: 22,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _isConnecting
                            ? languageProvider.getTranslation('processing')
                            : _connectedDevice != null
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
                      backgroundColor: _isConnecting
                          ? Colors.grey
                          : _connectedDevice != null
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
        );
      },
    );
  }

  Widget _buildCardSection(
      String title,
      List<BluetoothDevice> devices,
      bool isNearby,
      LanguageProvider languageProvider,
      {double maxHeight = 200}
      ) {
    bool isPaired = title == languageProvider.getTranslation('paired_podiums');
    Color headerColor = const Color(0xFF4DB6AC);
    Color headerTextColor = const Color(0xFF00695C);
    IconData titleIcon = isPaired ? Icons.bluetooth_searching : Icons.bluetooth;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: headerColor, width: 1.5),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                      Icon(titleIcon, color: headerTextColor, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: headerTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isScanning ? null : _startDiscovery,
                  icon: _isScanning
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(headerTextColor),
                    ),
                  )
                      : Icon(Icons.refresh, color: headerTextColor, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(
            height: maxHeight,
            child: devices.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isNearby ? Icons.bluetooth_disabled : Icons.bluetooth_searching,
                    size: 36,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isNearby
                          ? languageProvider.getTranslation('no_devices_found')
                          : languageProvider.getTranslation('no_paired_podiums'),
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
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  BluetoothDevice device = devices[index];
                  bool isConnected = _connectedDevice?.address == device.address;
                  bool isSelected = _selectedDevice?.address == device.address;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDevice = device);
                    },
                    child: _buildDeviceItem(
                      "${index + 1}. ${device.name ?? device.address}",
                      Icons.speaker,
                      isConnected ? Colors.green : (isNearby ? Colors.grey[700]! : Colors.blue),
                      device: device,
                      isConnected: isConnected,
                      isSelected: isSelected,
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

  Widget _buildDeviceItem(
      String name,
      IconData icon,
      Color iconColor,
      {BluetoothDevice? device, bool isConnected = false, bool isSelected = false}
      ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected ? Colors.green : isSelected ? Colors.blue : Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (isConnected)
            Icon(Icons.link, color: Colors.green, size: 18),
        ],
      ),
    );
  }
}