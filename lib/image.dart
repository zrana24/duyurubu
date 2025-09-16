import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import 'language.dart';

class ImageWidget extends StatefulWidget {
  final double? height;
  final double? width;
  final BoxFit fit;
  final bool showBluetoothStatus;
  final BluetoothConnection? connection;
  final BluetoothDevice? connectedDevice;

  const ImageWidget({
    Key? key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.showBluetoothStatus = true,
    this.connection,
    this.connectedDevice,
  }) : super(key: key);

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> with TickerProviderStateMixin {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.showBluetoothStatus) {
      _initBluetooth();
    }

    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.connectedDevice != null) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connectedDevice != null && oldWidget.connectedDevice == null) {
      _animationController.repeat(reverse: true);
    } else if (widget.connectedDevice == null && oldWidget.connectedDevice != null) {
      _animationController.stop();
    }
  }

  void _initBluetooth() async {
    try {
      _bluetoothState = await FlutterBluetoothSerial.instance.state;
      FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
        if (mounted) {
          setState(() {
            _bluetoothState = state;
          });
        }
      });
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Bluetooth initialization error: $e');
    }
  }

  Widget _buildBluetoothOverlay(LanguageProvider languageProvider, BuildContext context) {
    if (!widget.showBluetoothStatus) return SizedBox.shrink();

    double fontSize = MediaQuery.of(context).size.width * 0.03;

    if (_bluetoothState != BluetoothState.STATE_ON) {
      return Positioned(
        top: 8,
        right: 8,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 6),
              Text(
                '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.connectedDevice != null && widget.connection != null) {
      String deviceName = widget.connectedDevice!.name ?? widget.connectedDevice!.address;

      return Positioned(
        top: 48,
        right: 10,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bluetooth_connected, color: Colors.white, size: fontSize),
              ),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  "$deviceName BAĞLI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }
    else {
      return Positioned(
        top: 30,
        right: 8,
        child: Text(
          "",
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          child: Stack(
            children: [
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: double.infinity,
                  ),
                  child: Image.asset(
                    'assets/images/footer.png',
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                  ),
                ),
              ),
              _buildBluetoothOverlay(languageProvider, context),
            ],
          ),
        );
      },
    );
  }
}

class ImageWidgetController {
  static final Map<String, GlobalKey<_ImageWidgetState>> _keys = {};

  static GlobalKey<_ImageWidgetState> getKey(String id) {
    _keys[id] ??= GlobalKey<_ImageWidgetState>();
    return _keys[id]!;
  }

  static void dispose(String id) {
    _keys.remove(id);
  }
}