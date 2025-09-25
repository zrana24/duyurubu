import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'language.dart';

class ImageWidget extends StatefulWidget {
  final double? height;
  final double? width;
  final BoxFit fit;
  final bool showBluetoothStatus;
  final BluetoothDevice? connectedDevice;

  const ImageWidget({
    Key? key,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.showBluetoothStatus = true,
    this.connectedDevice,
  }) : super(key: key);

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> with TickerProviderStateMixin {
  BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;
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
      // Flutter Blue Plus için bluetooth state alma
      _bluetoothState = await FlutterBluePlus.adapterState.first;

      // State değişikliklerini dinle
      FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
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
      // Hata durumunda default state set et
      if (mounted) {
        setState(() {
          _bluetoothState = BluetoothAdapterState.unknown;
        });
      }
    }
  }

  Widget _buildBluetoothOverlay(LanguageProvider languageProvider, BuildContext context) {
    if (!widget.showBluetoothStatus) return SizedBox.shrink();

    double fontSize = MediaQuery.of(context).size.width * 0.03;

    // Bluetooth kapalı durumu
    if (_bluetoothState != BluetoothAdapterState.on) {
      return Positioned(
        top: 8,
        right: 8,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bluetooth_disabled, color: Colors.red, size: fontSize + 4),
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

    // Cihaz bağlı durumu
    if (widget.connectedDevice != null) {
      String deviceName = widget.connectedDevice!.platformName.isNotEmpty
          ? widget.connectedDevice!.platformName
          : widget.connectedDevice!.remoteId.str;

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
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bluetooth_connected,
                        color: Colors.white,
                        size: fontSize,
                      ),
                    ),
                  );
                },
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
    // Bluetooth açık ama cihaz bağlı değil
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