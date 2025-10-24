import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;

  List<Map<String, String>> _speakers = [];

  List<Map<String, dynamic>> _contents = [];

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnecting => _isConnecting;
  List<Map<String, String>> get speakers => _speakers;
  List<Map<String, dynamic>> get contents => _contents;

  void setConnecting(bool connecting) {
    _isConnecting = connecting;
    notifyListeners();
  }

  void setConnectedDevice(BluetoothDevice? device) {
    _connectedDevice = device;
    notifyListeners();
  }

  void updateSpeakers(List<Map<String, String>> newSpeakers) {
    _speakers = newSpeakers;
    notifyListeners();
  }

  void addSpeaker(Map<String, String> speaker) {
    _speakers.add(speaker);
    notifyListeners();
  }

  void clearSpeakers() {
    _speakers.clear();
    notifyListeners();
  }

  void updateContents(List<Map<String, dynamic>> newContents) {
    _contents = newContents;
    notifyListeners();
  }

  void addContent(Map<String, dynamic> content) {
    _contents.add(content);
    notifyListeners();
  }

  void deleteContent(int index) {
    _contents.removeAt(index);
    notifyListeners();
  }

  void clearContents() {
    _contents.clear();
    notifyListeners();
  }

  void setWriteCharacteristic(BluetoothCharacteristic characteristic) {
    _writeCharacteristic = characteristic;
  }

  void setReadCharacteristic(BluetoothCharacteristic characteristic) {
    _readCharacteristic = characteristic;
    _listenForData();
  }

  void _listenForData() {
    _readCharacteristic?.onValueReceived.listen((value) {
      if (value.isNotEmpty) {
        try {
          String receivedString = utf8.decode(value);
          Map<String, dynamic> receivedData = jsonDecode(receivedString);
          print('Bluetoothdan gelen veri: $receivedData');

          _handleReceivedData(receivedData);
        } catch (e) {
          print('Veri decode hatası: $e');
        }
      }
    });
  }

  void _handleReceivedData(Map<String, dynamic> data) {
    if (data.containsKey('speakers') && data['speakers'] is List) {
      List<Map<String, String>> newSpeakers = [];
      for (var speakerData in data['speakers']) {
        newSpeakers.add({
          "title": speakerData['department']?.toString() ?? '',
          "person": speakerData['name']?.toString() ?? '',
          "time": speakerData['duration']?.toString() ?? '00:00:00',
        });
      }
      updateSpeakers(newSpeakers);
    }
    else if (data.containsKey('department') && data.containsKey('name')) {
      addSpeaker({
        "title": data['department']?.toString() ?? '',
        "person": data['name']?.toString() ?? '',
        "time": data['duration']?.toString() ?? '00:00:00',
      });
    }
    else if (data.containsKey('operation') && data['operation'] == 1) {
      if (data.containsKey('contents') && data['contents'] is List) {
        List<Map<String, dynamic>> newContents = [];
        for (var contentData in data['contents']) {
          newContents.add({
            "id": contentData['id']?.toString() ?? '',
            "title": contentData['title']?.toString() ?? '',
            "startTime": contentData['startTime']?.toString() ?? '00:00:00',
            "endTime": contentData['endTime']?.toString() ?? '00:00:00',
            "type": contentData['type']?.toString() ?? 'document',
            "file": contentData['file']?.toString() ?? '',
          });
        }
        updateContents(newContents);
      } else if (data.containsKey('title')) {
        addContent({
          "id": data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          "title": data['title']?.toString() ?? '',
          "startTime": data['startTime']?.toString() ?? '00:00:00',
          "endTime": data['endTime']?.toString() ?? '00:00:00',
          "type": data['type']?.toString() ?? 'document',
          "file": data['file']?.toString() ?? '',
        });
      }
    }
  }

  Future<void> sendSpeakerData(Map<String, dynamic> data) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      print('Bağlı cihaz veya yazma karakteristiği yok');
      return;
    }

    try {
      String jsonData = jsonEncode(data);
      List<int> bytes = utf8.encode(jsonData);

      await _writeCharacteristic!.write(bytes);
      print('Speaker verisi gönderildi: $jsonData');
    } catch (e) {
      print('Speaker verisi gönderme hatası: $e');
    }
  }

  Future<void> sendContentData(Map<String, dynamic> data) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      print('Bağlı cihaz veya yazma karakteristiği yok');
      return;
    }

    try {
      Map<String, dynamic> sendData = {
        "operation": 1,
        "title": data['title'],
        "startTime": data['startTime'],
        "endTime": data['endTime'],
        "file": data['file']?.path ?? "",
      };

      String jsonData = jsonEncode(sendData);
      List<int> bytes = utf8.encode(jsonData);

      await _writeCharacteristic!.write(bytes);
      print('İçerik verisi gönderildi: $jsonData');
    } catch (e) {
      print('İçerik verisi gönderme hatası: $e');
    }
  }

  Future<void> sendDeleteContent(int index) async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      print('Bağlı cihaz veya yazma karakteristiği yok');
      return;
    }

    try {
      Map<String, dynamic> sendData = {
        "operation": 1,
        "deleteIndex": index,
      };

      String jsonData = jsonEncode(sendData);
      List<int> bytes = utf8.encode(jsonData);

      await _writeCharacteristic!.write(bytes);
      print('İçerik silme gönderildi: $jsonData');
    } catch (e) {
      print('İçerik silme hatası: $e');
    }
  }

  Future<void> requestContentData() async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      print('Bağlı cihaz veya yazma karakteristiği yok');
      return;
    }

    try {
      Map<String, dynamic> requestData = {
        "operation": 1,
        "request": "getContents"
      };

      String jsonData = jsonEncode(requestData);
      List<int> bytes = utf8.encode(jsonData);

      await _writeCharacteristic!.write(bytes);
      print('İçerik verisi istendi: $jsonData');
    }
    catch (e) {
      print('İçerik verisi isteme hatası: $e');
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting || _connectedDevice != null) return;

    try {
      setConnecting(true);
      await device.connect(autoConnect: false, timeout: Duration(seconds: 8));
      _connectedDevice = device;

      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            setWriteCharacteristic(characteristic);
          }

          if (characteristic.properties.read || characteristic.properties.notify) {
            setReadCharacteristic(characteristic);
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
            }
          }
        }
      }

      device.connectionState.listen((state) {
        print('Cihaz bağlantı durumu: $state');
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _writeCharacteristic = null;
          _readCharacteristic = null;
          _speakers.clear();
          _contents.clear();
          notifyListeners();
        }
      });

      notifyListeners();
    } catch (e) {
      print('Bağlantı hatası: $e');
      _connectedDevice = null;
      _writeCharacteristic = null;
      _readCharacteristic = null;
      _speakers.clear();
      _contents.clear();
      notifyListeners();
    } finally {
      setConnecting(false);
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print('Bağlantı kesme hatası: $e');
      } finally {
        _connectedDevice = null;
        _writeCharacteristic = null;
        _readCharacteristic = null;
        _speakers.clear();
        _contents.clear();
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