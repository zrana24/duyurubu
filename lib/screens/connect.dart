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
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN; // Bluetooth mevcut durumu
  List<BluetoothDevice> _devicesList = []; // Çevredeki cihazlar
  List<BluetoothDevice> _pairedDevicesList = []; //Eşleşen cihazlar
  BluetoothConnection? _connection; //Seçilen cihazla bağlantı
  bool _isConnecting = false; // Bağlantı durumu
  bool _isScanning = false; // Tarama durumu
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription; // Tarama sonucu
  BluetoothDevice? _connectedDevice; // Bağlı cihaz
  BluetoothDevice? _selectedDevice; // Seçilen cihaz

  @override
  void initState() { //Sayfa açıldığında
    super.initState();
    _requestPermissions().then((_) => _initBluetooth());  //Bluetooth izinlerini başlatma
  }

  @override
  void dispose() { //Sayfa Kapanırken
    _streamSubscription?.cancel(); // Tarama sonucu iptal
    _connection?.dispose(); // Bağlantıyı kapat
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan, // Cihaz taramak izni
      Permission.bluetoothConnect, //Cihaza bağlanma izni
      Permission.locationWhenInUse, //Konum izni
    ].request();
  }

  void _initBluetooth() async {
    try {
      BluetoothState state = await FlutterBluetoothSerial.instance.state; //Bluetooth durumu
      setState(() => _bluetoothState = state); //Bluetooth durumunu güncelleme

      _getPairedDevices(); //Eşleşen cihazları alır
      _startDiscovery(); //Taramayı başlatır

      //Bluetooth durumu değiştiğinde çalışır
      FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
        setState(() => _bluetoothState = state);
        _getPairedDevices(); //Eşleşen cihazları alır
        _startDiscovery(); //Taramayı başlatır
      });
    } catch (_) {}
  }

  void _getPairedDevices() async { //Eşleşen cihazları listeleme fonksiyonu
    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices(); //Eşleşen cihazları alır
      setState(() => _pairedDevicesList = devices); //Eşleşen cihazları listeye aktar
    } catch (_) {}
  }

  void _startDiscovery() { //Taramayı başlatır
    if (_isScanning) return; //Tarama zaten devam ediyorsa iptal et

    setState(() {
      _isScanning = true;
      _devicesList.clear(); //Önceki listeyi temizler.
    });

    _streamSubscription?.cancel(); // Önceki tarama varsa iptal et
    _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      // Eğer cihaz listede varsa güncelle, yoksa ekle
      final existingIndex = _devicesList.indexWhere((d) => d.address == r.device.address);
      if (existingIndex >= 0) {
        _devicesList[existingIndex] = r.device;
      } else {
        _devicesList.add(r.device);
      }
      if (mounted) setState(() {});  // Arayüzü günceller
    });

    _streamSubscription!.onDone(() { //Tarama bittiğinde çalışır
      if (mounted) setState(() => _isScanning = false); //Arayüzü günceller
    });

    Timer(Duration(seconds: 30), () { // 30 saniye sonra otomatik olarak taramayı durdur
      if (_isScanning) _stopDiscovery();
    });
  }

  void _stopDiscovery() {
    _streamSubscription?.cancel();
    if (mounted) setState(() => _isScanning = false);
  }

  void _connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);
    _stopDiscovery();

    try {
      if (_connection != null) await _connection!.close();
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        _connectedDevice = device;
        _isConnecting = false;
      });

      _connection!.input!.listen(
            (_) {},
        onDone: () {
          if (mounted) setState(() {
            _connection = null;
            _connectedDevice = null;
          });
        },
        onError: (_) {},
      );
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

    return Scaffold(
     backgroundColor: Color(0xFFE0E0E0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenSize.width * 0.04),
                child: Column(
                  children: [
                    SizedBox(height: screenSize.height * 0.01),
                    _buildCardSection(screenSize, 'EŞLEŞMİŞ KÜRSÜLER', _pairedDevicesList, false),
                    SizedBox(height: screenSize.height * 0.03),
                    _buildCardSection(screenSize, 'ÇEVREDEKİ CİHAZLAR', _devicesList, true),
                    SizedBox(height: screenSize.height * 0.15),
                  ],
                ),
              ),
            ),
            // Sabit buton
            Container(
              margin: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05, vertical: 8),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_connectedDevice != null) {
                    _disconnect();
                    setState(() {
                      _selectedDevice = null;
                    });
                  } else if (_selectedDevice != null) {
                    _connectToDevice(_selectedDevice!);
                  }
                },
                icon: Icon(
                  _connectedDevice != null ? Icons.link_off : Icons.bluetooth,
                  color: Colors.white, // ikon rengi beyaz
                  size: screenSize.width * 0.06,
                ),
                label: Text(
                  _connectedDevice != null ? 'BAĞLANTIYI KES' : 'BAĞLAN',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.045,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // yazı rengi beyaz
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                  backgroundColor: _connectedDevice != null ? Colors.red : Color(0xFF546E7A),
                  foregroundColor: Colors.white, // ikon ve yazıyı beyaz yapar
                ),
              ),
            ),

            AppFooter(activeTab: "BAĞLANTI"),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSection(Size screenSize, String title, List<BluetoothDevice> devices, bool isNearby) {
    bool isPaired = title == 'EŞLEŞMİŞ KÜRSÜLER';
    Color headerColor = const Color(0xFF4DB6AC);
    Color headerTextColor = const Color(0xFF00695C);
    IconData titleIcon = isPaired
        ? const IconData(0xe0e6, fontFamily: 'MaterialIcons')
        : Icons.bluetooth;

    double headerHeight = screenSize.height * 0.05;
    double deviceItemHeight = screenSize.height * 0.09;

    int maxVisibleDevices = 4;

    bool enableScroll = devices.length > maxVisibleDevices;

    double cardMaxHeight = deviceItemHeight * (devices.length > maxVisibleDevices ? maxVisibleDevices : devices.length)
        + headerHeight + 16;

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
            padding: EdgeInsets.symmetric(vertical: headerHeight * 0.1, horizontal: screenSize.width * 0.03),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(titleIcon, color: headerTextColor, size: screenSize.width * 0.06),
                    SizedBox(width: screenSize.width * 0.02),
                    Text(
                      title,
                      style: TextStyle(
                        color: headerTextColor,
                        fontSize: screenSize.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _startDiscovery,
                  icon: Icon(Icons.refresh, color: headerTextColor, size: screenSize.width * 0.06),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: cardMaxHeight,
            ),
            child: devices.isEmpty
                ? Center(
              child: Padding(
                padding: EdgeInsets.all(screenSize.width * 0.04),
                child: Text(
                  isNearby ? 'Çevrede cihaz bulunamadı' : 'Eşleşmiş cihaz bulunamadı',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: screenSize.width * 0.045,
                  ),
                ),
              ),
            )
                : ListView.builder(
              physics: enableScroll ? BouncingScrollPhysics() : NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = devices[index];
                bool isConnected = _connectedDevice?.address == device.address;
                bool isSelected = _selectedDevice?.address == device.address;
                return GestureDetector(
                  onTap: () {
                    if (!isConnected) {
                      setState(() {
                        _selectedDevice = device;
                      });
                    }
                  },
                  child: _buildDeviceItem(
                    "${index + 1}. ${device.name ?? device.address}",
                    Icons.speaker,
                    isConnected ? Colors.green : (isNearby ? Colors.grey[700]! : Colors.blue),
                    isNearby,
                    screenSize,
                    device: device,
                    isConnected: isConnected,
                    isSelected: isSelected,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(String name, IconData icon, Color iconColor, bool isNearby, Size screenSize,
      {BluetoothDevice? device, bool isConnected = false, bool isSelected = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenSize.width * 0.03, vertical: screenSize.height * 0.008),
      padding: EdgeInsets.all(screenSize.width * 0.035),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isConnected ? Colors.green : Colors.grey[400]!, width: isConnected ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenSize.width * 0.025),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: screenSize.width * 0.07),
          ),
          SizedBox(width: screenSize.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: screenSize.width * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                if (device != null && device.address.isNotEmpty)
                  Text(device.address,
                      style: TextStyle(fontSize: screenSize.width * 0.037, color: Colors.grey[600])),
                if (isConnected)
                  Text('Bağlı',
                      style: TextStyle(
                          fontSize: screenSize.width * 0.037, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (device != null)
            _isConnecting && _connectedDevice?.address == device.address
                ? SizedBox(
              width: screenSize.width * 0.06,
              height: screenSize.width * 0.06,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(
              isConnected ? Icons.check_circle : Icons.bluetooth,
              color: isConnected ? Colors.green : Color(0xFF03A9F4),
              size: screenSize.width * 0.07,
            ),
        ],
      ),
    );
  }
}
