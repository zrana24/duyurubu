import 'package:flutter/material.dart';
import 'dart:async';
import 'footer.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import '../image.dart';
import '../bluetooth_provider.dart';

class Management extends StatefulWidget {
  const Management({Key? key}) : super(key: key);

  @override
  State<Management> createState() => _ManagementState();
}

class _ManagementState extends State<Management> {
  final List<Map<String, String>> speakers = [
    {
      "title": "Satış ve Pazarlama Müdürü",
      "person": "Macit AHISKALI",
      "time": "00:30:00",
    },
    {
      "title": "YAZILIMBU Birimi",
      "person": "Özkan ŞEN",
      "time": "00:30:00",
    },
    {
      "title": "Finans Direktörü",
      "person": "Elif YILMAZ",
      "time": "00:20:00",
    },
    {
      "title": "İK Müdürü",
      "person": "Ahmet KAYA",
      "time": "00:25:00",
    },
  ];

  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void dispose() {
    _departmentController.dispose();
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _showAddSpeakerDialog(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    _departmentController.clear();
    _nameController.clear();
    _timeController.text = '00:30:00';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(languageProvider.getTranslation('department'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _departmentController,
                  decoration: InputDecoration(
                    hintText: languageProvider.getTranslation('department_example'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(languageProvider.getTranslation('name'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: languageProvider.getTranslation('name_example'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(languageProvider.getTranslation('duration'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    hintText: languageProvider.getTranslation('duration_example'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(languageProvider.getTranslation('cancel')),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _saveSpeaker(context);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4DB6AC),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(languageProvider.getTranslation('save')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveSpeaker(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (_departmentController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _timeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.getTranslation('fill_all_fields')),
        backgroundColor: Colors.red,
      ));
      return;
    }

    String timeText = _timeController.text.trim();
    RegExp timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$');
    if (!timeRegex.hasMatch(timeText)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(languageProvider.getTranslation('invalid_time')),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      speakers.add({
        "title": _departmentController.text.trim(),
        "person": _nameController.text.trim(),
        "time": timeText,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(languageProvider.getTranslation('added_success')),
      backgroundColor: Colors.green,
    ));
  }

  Color _getCardColor(int index) {
    List<Color> colors = [const Color(0xFF4CAF50), const Color(0xFFFF9800)];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: screenHeight * 0.10,
        flexibleSpace: Container(
          width: double.infinity,
          height: double.infinity,
          child: ImageWidget(
            fit: BoxFit.cover,
            showBluetoothStatus: true,
            connection: bluetoothProvider.connection,
            connectedDevice: bluetoothProvider.connectedDevice,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015,
                        horizontal: screenWidth * 0.04,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4DB6AC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Container(
                                  width: screenWidth * 0.15,
                                  height: screenWidth * 0.08,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00695C),
                                    borderRadius: BorderRadius.circular(screenWidth * 0.1),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Text(
                                    languageProvider.getTranslation('name_screen'),
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF00695C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showAddSpeakerDialog(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.005,
                                  vertical: screenHeight * 0.005
                              ),
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 1.5)
                              ),
                              child: Text(
                                languageProvider.getTranslation('add_name'),
                                style: TextStyle(
                                    fontSize: screenWidth * 0.032,
                                    color: const Color(0xFF00695C),
                                    fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                        child: ListView.builder(
                          padding: EdgeInsets.only(
                            top: screenHeight * 0.005,
                            bottom: screenHeight * 0.02,
                          ),
                          itemCount: speakers.length,
                          itemBuilder: (context, index) {
                            final speaker = speakers[index];
                            return AICard(
                              title: speaker['title']!,
                              person: speaker['person']!,
                              initialTime: speaker['time']!,
                              backgroundColor: _getCardColor(index),
                              borderColor: _getCardColor(index),
                              number: (index + 1).toString(),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            AppFooter(activeTab: "management"),
          ],
        ),
      ),
    );
  }
}

// AICard class remains the same
class AICard extends StatefulWidget {
  final String title;
  final String person;
  final String initialTime;
  final Color backgroundColor;
  final Color borderColor;
  final String number;

  const AICard({
    Key? key,
    required this.title,
    required this.person,
    required this.initialTime,
    required this.backgroundColor,
    required this.borderColor,
    required this.number,
  }) : super(key: key);

  @override
  State<AICard> createState() => _AICardState();
}

class _AICardState extends State<AICard> {
  late Duration _duration;
  late Duration _initialDuration;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    final timeParts = widget.initialTime.split(':');
    _initialDuration = Duration(
      hours: int.parse(timeParts[0]),
      minutes: int.parse(timeParts[1]),
      seconds: int.parse(timeParts[2]),
    );
    _duration = _initialDuration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) {
      _pauseTimer();
      return;
    }

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_duration.inSeconds > 0) {
          _duration = _duration - const Duration(seconds: 1);
        } else {
          _pauseTimer();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() {
      _duration = _initialDuration;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.number}. ${languageProvider.getTranslation('speaker_info')}',
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight * 0.010),
            Row(
              children: [
                Icon(Icons.business_center, size: screenWidth * 0.05, color: Colors.grey[700]),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  child: Icon(Icons.close, color: Colors.red[400], size: screenWidth * 0.08),
                ),
                SizedBox(width: screenWidth * 0.015),
                Container(
                  width: screenWidth * 0.10,
                  height: screenWidth * 0.10,
                  color: Colors.grey[200],
                  child: Icon(Icons.add, color: Colors.grey[700], size: screenWidth * 0.08),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.010),
            Row(
              children: [
                Icon(Icons.person, size: screenWidth * 0.05, color: Colors.grey[700]),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    widget.person,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _startTimer,
                  child: Container(
                    child: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.grey[700],
                        size: screenWidth * 0.09
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.015),
                GestureDetector(
                  onTap: _resetTimer,
                  child: Container(
                    width: screenWidth * 0.10,
                    height: screenWidth * 0.10,
                    color: Colors.grey[200],
                    child: Icon(Icons.remove, color: Colors.grey[700], size: screenWidth * 0.08),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.012),
            Row(
              children: [
                Icon(Icons.access_time, size: screenWidth * 0.045, color: widget.backgroundColor),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: widget.backgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}