import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'footer.dart';

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

  void _getPairedDevices() async {
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

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
    });
    _stopDiscovery();

    try {
      if (_connection != null) await _connection!.close();

      BluetoothConnection connection =
      await BluetoothConnection.toAddress(device.address);

      setState(() {
        _connection = connection;
        _connectedDevice = device;
        _isConnecting = false;
      });

      _connection!.input!.listen((_) {},
          onDone: () {
            if (mounted)
              setState(() {
                _connection = null;
                _connectedDevice = null;
              });
          });
    } catch (_) {
      setState(() {
        _isConnecting = false;
        _connection = null;
        _connectedDevice = null;
      });
    }
  }

  void _disconnect() async {
    try {
      await _connection?.close();
      setState(() {
        _connection = null;
        _connectedDevice = null;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double cardPadding = 12;

    return Scaffold(
      backgroundColor: Color(0xFFE0E0E0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildCardSection(
                      'EŞLEŞMİŞ CİHAZLAR',
                      _pairedDevicesList,
                      false,
                      maxHeight: screenSize.height * 0.20),
                  SizedBox(height: 20),
                  _buildCardSection(
                      'ÇEVREDEKİ CİHAZLAR',
                      _devicesList,
                      true,
                      maxHeight: screenSize.height * 0.20),
                  SizedBox(height: 40),
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
                  } else if (_selectedDevice != null &&
                      _pairedDevicesList.any(
                              (d) => d.address == _selectedDevice!.address)) {
                    _connectToDevice(_selectedDevice!);
                  }
                },
                icon: Icon(
                  _connectedDevice != null ? Icons.link_off : Icons.bluetooth,
                  color: Colors.white,
                  size: 24,
                ),
                label: Text(
                  _connectedDevice != null
                      ? 'BAĞLANTIYI KES'
                      : (_selectedDevice != null &&
                      _pairedDevicesList.any(
                              (d) => d.address == _selectedDevice!.address))
                      ? 'BAĞLAN'
                      : 'EŞLEŞMİŞ CİHAZ SEÇİN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _connectedDevice != null
                      ? Colors.red
                      : (_selectedDevice != null &&
                      _pairedDevicesList.any(
                              (d) => d.address == _selectedDevice!.address))
                      ? Color(0xFF546E7A)
                      : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            AppFooter(activeTab: "BAĞLANTI"),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSection(
      String title, List<BluetoothDevice> devices, bool isNearby,
      {double maxHeight = 200}) {
    bool isPaired = title == 'EŞLEŞMİŞ KÜRSÜLER';
    Color headerColor = const Color(0xFF4DB6AC);
    Color headerTextColor = const Color(0xFF00695C);
    IconData titleIcon =
    isPaired ? const IconData(0xe0e6, fontFamily: 'MaterialIcons') : Icons.bluetooth;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: headerColor, width: 2),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(titleIcon, color: headerTextColor, size: 24),
                    SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: headerTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _isScanning ? null : _startDiscovery,
                  icon: _isScanning
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(headerTextColor),
                    ),
                  )
                      : Icon(Icons.refresh, color: headerTextColor, size: 24),
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
                    isNearby ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 10),
                  Text(
                    isNearby ? 'Çevrede cihaz bulunamadı' : 'Eşleşmiş cihaz bulunamadı',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
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
                      if (!isConnected && !isNearby) {
                        setState(() => _selectedDevice = device);
                      }
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

  Widget _buildDeviceItem(String name, IconData icon, Color iconColor,
      {BluetoothDevice? device, bool isConnected = false, bool isSelected = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isConnected ? Colors.green : isSelected ? Colors.blue : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          if (isConnected)
            Icon(Icons.link, color: Colors.green, size: 24),
        ],
      ),
    );
  }
}
