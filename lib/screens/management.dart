import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../language.dart';
import '../image.dart';
import '../bluetooth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Management extends StatefulWidget {
  const Management({Key? key}) : super(key: key);

  @override
  State<Management> createState() => _ManagementState();
}

class _ManagementState extends State<Management> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: Column(
        children: [
          Container(
            height: 60,
            width: double.infinity,
            child: ImageWidget(activePage: "management"),
          ),

          Expanded(
            child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
            ),
            child: const SpeakerManagement(),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
            ),
            child: const ContentManagement(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
            ),
            child: const SpeakerManagement(),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
            ),
            child: const ContentManagement(),
          ),
        ),
      ],
    );
  }
}

class SpeakerManagement extends StatefulWidget {
  const SpeakerManagement({Key? key}) : super(key: key);

  @override
  State<SpeakerManagement> createState() => _SpeakerManagementState();
}

class _SpeakerManagementState extends State<SpeakerManagement> {
  List<Map<String, dynamic>> _speakers = [
    {
      'department': 'Satış ve Pazarlama Müdürü',
      'name': 'Macit AHISKALI',
      'time': '00:30:00',
      'isEditing': false,
    }
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestSpeakerData();
    });
  }

  void _requestSpeakerData() {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    final requestData = {
      "operation": 0,
      "department": "",
      "name": "",
      "duration": ""
    };
    bluetoothProvider.sendSpeakerData(requestData);
  }

  void _addNewSpeaker() {
    setState(() {
      _speakers.add({
        'department': 'Bölüm/Departman',
        'name': 'Ad Soyad',
        'time': '00:30:00',
        'isEditing': true,
      });
    });
  }

  void _saveSpeaker(int index, String department, String name, String time) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);

    if (department.trim().isEmpty || name.trim().isEmpty || time.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.getTranslation('fill_all_fields')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    RegExp timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$');
    if (!timeRegex.hasMatch(time)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.getTranslation('invalid_time')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    final dataToSend = {
      "operation": 0,
      "department": department.trim(),
      "name": name.trim(),
      "duration": time,
    };

    bluetoothProvider.sendSpeakerData(dataToSend);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${languageProvider.getTranslation('added_success')}'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ));

    setState(() {
      _speakers[index] = {
        'department': department.trim(),
        'name': name.trim(),
        'time': time,
        'isEditing': false,
      };
    });
  }

  void _deleteSpeaker(int index) {
    setState(() {
      _speakers.removeAt(index);
    });
  }

  Color _getCardColor(int index) {
    List<Color> colors = [const Color(0xFF4CAF50), const Color(0xFFFF9800)];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF4DB6AC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00695C), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'İSİMLİK EKRANI',
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 16 : 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00695C),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _addNewSpeaker,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? 16 : 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Text(
                    'İSİM EKLE',
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 12 : 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00695C),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _speakers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: screenWidth > 600 ? 48 : 36,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Konuşmacı bulunamadı',
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 14 : 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                itemCount: _speakers.length,
                itemBuilder: (context, index) {
                  final speaker = _speakers[index];
                  return EditableSpeakerCard(
                    department: speaker['department'],
                    name: speaker['name'],
                    time: speaker['time'],
                    backgroundColor: _getCardColor(index),
                    borderColor: _getCardColor(index),
                    number: (index + 1).toString(),
                    isEditing: speaker['isEditing'],
                    onSave: (department, name, time) => _saveSpeaker(index, department, name, time),
                    onDelete: () => _deleteSpeaker(index),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ContentManagement extends StatefulWidget {
  const ContentManagement({Key? key}) : super(key: key);

  @override
  State<ContentManagement> createState() => _ContentManagementState();
}

class _ContentManagementState extends State<ContentManagement> {
  List<Map<String, dynamic>> _contents = [
    {
      'title': 'Küresel Isınma Toplantısına Hoş Geldiniz',
      'startTime': '00:30:00',
      'endTime': '00:30:00',
      'type': 'document',
      'file': null,
      'isEditing': false,
    }
  ];
  final ImagePicker _picker = ImagePicker();
  bool _showExportSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContentData();
    });
  }

  void _loadContentData() {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    bluetoothProvider.requestContentData();
  }

  void _addNewContent() {
    setState(() {
      _contents.add({
        'title': 'Toplantı Konusu',
        'startTime': '00:15:00',
        'endTime': '00:30:00',
        'type': 'document',
        'file': null,
        'isEditing': true,
      });
    });
  }

  Future<void> _pickFile(int index) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo, size: 22),
                title: const Text('Fotoğraf Seç', style: TextStyle(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _contents[index]['file'] = File(image.path);
                      _contents[index]['type'] = 'photo';
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, size: 22),
                title: const Text('Video Seç', style: TextStyle(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                  if (video != null) {
                    setState(() {
                      _contents[index]['file'] = File(video.path);
                      _contents[index]['type'] = 'video';
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.description, size: 22),
                title: const Text('Doküman Seç', style: TextStyle(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickDocument(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDocument(int index) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _contents[index]['file'] = File(result.files.single.path!);
          _contents[index]['type'] = 'document';
        });
      }
    } catch (e) {
      print("Dosya seçme hatası: $e");
    }
  }

  void _saveContent(int index, String title, String startTime, String endTime) {
    if (title.trim().isEmpty || startTime.trim().isEmpty || endTime.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Lütfen tüm alanları doldurun'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    RegExp timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$');

    if (!timeRegex.hasMatch(startTime) || !timeRegex.hasMatch(endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Geçersiz zaman formatı'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);
    Map<String, dynamic> contentData = {
      "title": title.trim(),
      "startTime": startTime,
      "endTime": endTime,
      "file": _contents[index]['file'],
    };

    bluetoothProvider.sendContentData(contentData);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('İçerik başarıyla eklendi'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ));

    setState(() {
      _contents[index] = {
        'title': title.trim(),
        'startTime': startTime,
        'endTime': endTime,
        'type': _contents[index]['type'],
        'file': _contents[index]['file'],
        'isEditing': false,
      };
    });
  }

  void _deleteContent(int index) {
    setState(() {
      _contents.removeAt(index);
    });
  }

  void _exportToComputer() async {
    if (_contents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Aktarılacak içerik bulunamadı.'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    setState(() {
      _showExportSuccess = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _showExportSuccess = false;
    });

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'İçerikleri Kaydet',
        fileName: 'toplanti_icerikleri_${DateTime.now().millisecondsSinceEpoch}.json',
      );

      if (outputFile != null) {
        final exportData = {
          'exportDate': DateTime.now().toIso8601String(),
          'contentCount': _contents.length,
          'contents': _contents,
        };
        print('İçerikler şu konuma kaydedildi: $outputFile');
      }
    } catch (e) {
      print('Aktarma hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF4DB6AC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00695C), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bilgi EKRANI',
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 14 : 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00695C),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (screenWidth > 400)
                    GestureDetector(
                      onTap: _exportToComputer,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 600 ? 16 : 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.computer, size: 16, color: Color(0xFF00695C)),
                            if (screenWidth > 500) const SizedBox(width: 6),
                            if (screenWidth > 500)
                              Text(
                                'Bilgisayara Aktar',
                                style: TextStyle(
                                  fontSize: screenWidth > 600 ? 12 : 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00695C),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addNewContent,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 16 : 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: Row(
                        children: [
                          if (screenWidth > 400)
                            Text(
                              'İÇERİK EKLE',
                              style: TextStyle(
                                fontSize: screenWidth > 600 ? 12 : 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00695C),
                              ),
                            ),
                          const SizedBox(width: 6),
                          const Icon(Icons.image, size: 16, color: Color(0xFF00695C)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _contents.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description,
                      size: screenWidth > 600 ? 48 : 36,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İçerik bulunamadı',
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 14 : 10,
                        color: const Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  final content = _contents[index];
                  return EditableContentCard(
                    title: content['title'],
                    startTime: content['startTime'],
                    endTime: content['endTime'],
                    type: content['type'],
                    file: content['file'],
                    isEditing: content['isEditing'],
                    onSave: (title, startTime, endTime) => _saveContent(index, title, startTime, endTime),
                    onFilePick: () => _pickFile(index),
                    onDelete: () => _deleteContent(index),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EditableSpeakerCard extends StatefulWidget {
  final String department;
  final String name;
  final String time;
  final Color backgroundColor;
  final Color borderColor;
  final String number;
  final bool isEditing;
  final Function(String, String, String) onSave;
  final VoidCallback onDelete;

  const EditableSpeakerCard({
    Key? key,
    required this.department,
    required this.name,
    required this.time,
    required this.backgroundColor,
    required this.borderColor,
    required this.number,
    required this.isEditing,
    required this.onSave,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<EditableSpeakerCard> createState() => _EditableSpeakerCardState();
}

class _EditableSpeakerCardState extends State<EditableSpeakerCard> {
  late TextEditingController _departmentController;
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  bool _isPlaying = false;
  bool _isSwitchActive = false;

  @override
  void initState() {
    super.initState();
    _departmentController = TextEditingController(text: widget.department);
    _nameController = TextEditingController(text: widget.name);
    _timeController = TextEditingController(text: widget.time);
  }

  @override
  void dispose() {
    _departmentController.dispose();
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _saveSpeaker() {
    widget.onSave(_departmentController.text, _nameController.text, _timeController.text);
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _toggleSwitch() {
    setState(() {
      _isSwitchActive = !_isSwitchActive;
    });
  }

  void _increaseTime() {
    print('Zaman artırıldı');
  }

  void _decreaseTime() {
    print('Zaman azaltıldı');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;

    final buttonSize = isTablet ? 50.0 : (isSmallScreen ? 40.0 : 45.0);
    final iconSize = isTablet ? 22.0 : (isSmallScreen ? 16.0 : 20.0);
    final spacing = isTablet ? 4.0 : (isSmallScreen ? 2.0 : 3.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: isTablet ? 140 : (isSmallScreen ? 120 : 130),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.borderColor, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                            Icons.info,
                            size: iconSize,
                            color: Colors.black
                        ),
                        SizedBox(width: spacing),
                        Flexible(
                          child: Text(
                            '${widget.number}. KONUŞMACI',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : (isSmallScreen ? 10 : 12),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: widget.isEditing
                        ? Row(
                      children: [
                        Icon(
                            Icons.business,
                            size: iconSize,
                            color: Colors.grey
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: TextField(
                            controller: _departmentController,
                            decoration: const InputDecoration(
                              hintText: 'Bölüm/Departman',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Icon(
                            Icons.business,
                            size: iconSize,
                            color: Colors.grey
                        ),
                        SizedBox(width: spacing),
                        Flexible(
                          child: Text(
                            widget.department,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: widget.isEditing
                        ? Row(
                      children: [
                        Icon(
                            Icons.person,
                            size: iconSize,
                            color: Colors.grey
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Ad Soyad',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Icon(
                            Icons.person,
                            size: iconSize,
                            color: Colors.grey
                        ),
                        SizedBox(width: spacing),
                        Flexible(
                          child: Text(
                            widget.name,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: widget.isEditing
                        ? Row(
                      children: [
                        Icon(
                            Icons.access_time,
                            size: iconSize,
                            color: Colors.grey
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: TextField(
                            controller: _timeController,
                            decoration: const InputDecoration(
                              hintText: '00:30:00',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Icon(
                            Icons.access_time,
                            size: iconSize,
                            color: Colors.grey
                        ),
                        SizedBox(width: spacing),
                        Flexible(
                          child: Text(
                            widget.time,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: spacing),
            Expanded(
              flex: 2,
              child: Container(
                height: double.infinity,
                child: widget.isEditing
                    ? Center(
                  child: Container(
                    width: buttonSize * 0.9,
                    height: buttonSize * 0.9,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: IconButton(
                      onPressed: _saveSpeaker,
                      icon: Icon(
                        Icons.check,
                        size: iconSize * 0.9,
                        color: Colors.green,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: buttonSize * 0.9),
                        Container(
                          width: buttonSize * 0.9,
                          height: buttonSize * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey, width: 2),
                          ),
                          child: IconButton(
                            onPressed: _increaseTime,
                            icon: Icon(
                              Icons.add,
                              size: iconSize * 0.9,
                              color: Colors.black,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        Container(
                          width: buttonSize * 0.9,
                          height: buttonSize * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey, width: 2),
                          ),
                          child: IconButton(
                            onPressed: widget.onDelete,
                            icon: Icon(
                              Icons.close,
                              size: iconSize * 0.9,
                              color: Colors.red,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: buttonSize * 0.9,
                          height: buttonSize * 0.9,
                          child: Center(
                            child: Transform.scale(
                              scale: 0.7,
                              child: Switch(
                                value: _isSwitchActive,
                                onChanged: (bool value) {
                                  setState(() {
                                    _isSwitchActive = value;
                                  });
                                },
                                activeColor: Color(0xFF4CAF50),
                                activeTrackColor: Color(0xFFA5D6A7),
                                inactiveThumbColor: Color(0xFF9E9E9E),
                                inactiveTrackColor: Color(0xFFE0E0E0),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: buttonSize * 0.9,
                          height: buttonSize * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey, width: 2),
                          ),
                          child: IconButton(
                            onPressed: _decreaseTime,
                            icon: Icon(
                              Icons.remove,
                              size: iconSize * 0.9,
                              color: Colors.black,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        Container(
                          width: buttonSize * 0.9,
                          height: buttonSize * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey, width: 2),
                          ),
                          child: IconButton(
                            onPressed: _togglePlay,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: iconSize * 0.9,
                              color: const Color(0xFF616161),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditableContentCard extends StatefulWidget {
  final String title;
  final String startTime;
  final String endTime;
  final String type;
  final File? file;
  final bool isEditing;
  final Function(String, String, String) onSave;
  final VoidCallback onFilePick;
  final VoidCallback onDelete;

  const EditableContentCard({
    Key? key,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.file,
    required this.isEditing,
    required this.onSave,
    required this.onFilePick,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<EditableContentCard> createState() => _EditableContentCardState();
}

class _EditableContentCardState extends State<EditableContentCard> {
  late TextEditingController _titleController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _startTimeController = TextEditingController(text: widget.startTime);
    _endTimeController = TextEditingController(text: widget.endTime);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _saveContent() {
    widget.onSave(_titleController.text, _startTimeController.text, _endTimeController.text);
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _increaseTime() {
    print('Zaman artırıldı');
  }

  void _decreaseTime() {
    print('Zaman azaltıldı');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 400;

    final buttonSize = isTablet ? 48.0 : (isSmallScreen ? 38.0 : 42.0);
    final iconSize = isTablet ? 20.0 : (isSmallScreen ? 14.0 : 18.0);
    final spacing = isTablet ? 4.0 : (isSmallScreen ? 2.0 : 3.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: isTablet ? 150 : (isSmallScreen ? 130 : 140),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                            Icons.info,
                            size: iconSize,
                            color: Colors.black
                        ),
                        SizedBox(width: spacing),
                        Text(
                          '1. İÇERİK',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : (isSmallScreen ? 10 : 12),
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing/2),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: widget.isEditing
                        ? Row(
                      children: [
                        Icon(
                            Icons.title,
                            size: iconSize,
                            color: Colors.grey
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: 'Toplantı Konusu',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: isTablet ? 18 : (isSmallScreen ? 14 : 16),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Icon(
                            Icons.title,
                            size: iconSize,
                            color: Colors.grey
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: isTablet ? 18 : (isSmallScreen ? 14 : 16),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing/2),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                      Icons.access_time,
                                      size: iconSize * 0.8,
                                      color: Colors.black
                                  ),
                                  SizedBox(width: spacing / 2),
                                  Text(
                                    'Başlangıç',
                                    style: TextStyle(
                                      fontSize: isTablet ? 12 : (isSmallScreen ? 9 : 11),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: spacing / 2),
                              widget.isEditing
                                  ? Row(
                                children: [
                                  Icon(
                                      Icons.play_arrow,
                                      size: iconSize * 0.8,
                                      color: Colors.grey
                                  ),
                                  SizedBox(width: spacing / 2),
                                  Expanded(
                                    child: TextField(
                                      controller: _startTimeController,
                                      decoration: const InputDecoration(
                                        hintText: '00:30:00',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                                        isDense: true,
                                      ),
                                      style: TextStyle(
                                        fontSize: isTablet ? 14 : (isSmallScreen ? 11 : 13),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                                  : Row(
                                children: [
                                  Icon(
                                      Icons.play_arrow,
                                      size: iconSize * 0.8,
                                      color: Colors.grey
                                  ),
                                  SizedBox(width: spacing / 2),
                                  Text(
                                    widget.startTime,
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : (isSmallScreen ? 11 : 13),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                      Icons.access_time,
                                      size: iconSize * 0.8,
                                      color: Colors.black
                                  ),
                                  SizedBox(width: spacing / 2),
                                  Text(
                                    'Bitiş',
                                    style: TextStyle(
                                      fontSize: isTablet ? 12 : (isSmallScreen ? 9 : 11),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: spacing / 2),
                              widget.isEditing
                                  ? Row(
                                children: [
                                  Icon(
                                      Icons.stop,
                                      size: iconSize * 0.8,
                                      color: Colors.grey
                                  ),
                                  SizedBox(width: spacing / 2),
                                  Expanded(
                                    child: TextField(
                                      controller: _endTimeController,
                                      decoration: const InputDecoration(
                                        hintText: '00:30:00',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                                        isDense: true,
                                      ),
                                      style: TextStyle(
                                        fontSize: isTablet ? 14 : (isSmallScreen ? 11 : 13),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                                  : Row(
                                children: [
                                  Icon(
                                      Icons.stop,
                                      size: iconSize * 0.8,
                                      color: Colors.grey
                                  ),
                                  SizedBox(width: spacing / 2),
                                  Text(
                                    widget.endTime,
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : (isSmallScreen ? 11 : 13),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: spacing),
            Expanded(
              flex: 2,
              child: Container(
                height: double.infinity,
                child: widget.isEditing
                    ? Center(
                  child: Container(
                    width: buttonSize * 1.1,
                    height: buttonSize * 1.1,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    child: IconButton(
                      onPressed: _saveContent,
                      icon: Icon(
                        Icons.check,
                        size: iconSize * 1.1,
                        color: Colors.green,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: buttonSize * 0.8,
                            height: buttonSize * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey, width: 2),
                            ),
                            child: IconButton(
                              onPressed: _increaseTime,
                              icon: Icon(
                                Icons.add,
                                size: iconSize * 0.8,
                                color: Colors.black,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          SizedBox(width: 4),
                          Container(
                            width: buttonSize * 0.8,
                            height: buttonSize * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey, width: 2),
                            ),
                            child: IconButton(
                              onPressed: widget.onDelete,
                              icon: Icon(
                                Icons.close,
                                size: iconSize * 0.8,
                                color: Colors.red,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: buttonSize * 0.8,
                            height: buttonSize * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey, width: 2),
                            ),
                            child: IconButton(
                              onPressed: _decreaseTime,
                              icon: Icon(
                                Icons.remove,
                                size: iconSize * 0.8,
                                color: Colors.black,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          SizedBox(width: 4),
                          Container(
                            width: buttonSize * 0.8,
                            height: buttonSize * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey, width: 2),
                            ),
                            child: IconButton(
                              onPressed: _togglePlay,
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                size: iconSize * 0.8,
                                color: const Color(0xFF616161),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}