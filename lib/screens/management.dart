import 'package:flutter/material.dart';
import 'dart:async';
import 'footer.dart'; // Footer import

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
      "color": "0xFF4CAF50"
    },
    {
      "title": "YAZILIMBU Birimi",
      "person": "Özkan ŞEN",
      "time": "00:30:00",
      "color": "0xFFFF9800"
    },
    {
      "title": "Finans Direktörü",
      "person": "Elif YILMAZ",
      "time": "00:20:00",
      "color": "0xFF2196F3"
    },
    {
      "title": "İK Müdürü",
      "person": "Ahmet KAYA",
      "time": "00:25:00",
      "color": "0xFFE91E63"
    },
  ];

  // Form için controller'lar
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

  void _showAddSpeakerDialog() {
    // Form alanlarını temizle
    _departmentController.clear();
    _nameController.clear();
    _timeController.text = '00:30:00';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4DB6AC),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bölüm/Pozisyon:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _departmentController,
                  decoration: InputDecoration(
                    hintText: 'Örn: Satış ve Pazarlama Müdürü',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4DB6AC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Ad Soyad
                const Text(
                  'Ad Soyad:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Örn: Ahmet YILMAZ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4DB6AC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Süre
                const Text(
                  'Sunum Süresi:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    hintText: 'Örn: 00:30:00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4DB6AC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF4DB6AC), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),

                // Butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'İPTAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _saveSpeaker();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4DB6AC),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'KAYDET',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
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

  void _saveSpeaker() {
    // Form validasyonu
    if (_departmentController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _timeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Süre formatı validasyonu (SS:DD:SS)
    String timeText = _timeController.text.trim();
    RegExp timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])$');

    if (!timeRegex.hasMatch(timeText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir süre formatı girin! (SS:DD:SS)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Varsayılan renk seç (döngüsel olarak)
    Color defaultColor = const Color(0xFF4CAF50);
    if (speakers.isNotEmpty) {
      List<Color> colors = [
        const Color(0xFF4CAF50),
        const Color(0xFFFF9800),
        const Color(0xFF2196F3),
        const Color(0xFFE91E63),
        const Color(0xFF9C27B0),
        const Color(0xFF00BCD4),
        const Color(0xFFFF5722),
        const Color(0xFF795548),
      ];
      defaultColor = colors[speakers.length % colors.length];
    }

    // Yeni konuşmacı ekle
    setState(() {
      speakers.add({
        "title": _departmentController.text.trim(),
        "person": _nameController.text.trim(),
        "time": timeText,
        "color": '0x${defaultColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Konuşmacı başarıyla eklendi!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  screenWidth * 0.04,
                  screenHeight * 0.02,
                  screenWidth * 0.04,
                  screenHeight * 0.01,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4DB6AC),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    // Üst başlık
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015,
                        horizontal: screenWidth * 0.04,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4DB6AC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                // Dikdörtgen
                                Container(
                                  width: screenWidth * 0.15,
                                  height: screenWidth * 0.08,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00695C),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(screenWidth * 0.1),
                                      topRight: Radius.circular(screenWidth * 0.1),
                                      bottomLeft: Radius.circular(screenWidth * 0.2),
                                      bottomRight: Radius.circular(screenWidth * 0.2),
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Text(
                                    'İSİMLİK EKRANI',
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
                            onTap: _showAddSpeakerDialog,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                                vertical: screenHeight * 0.004,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: Text(
                                'İSİM EKLE AI',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.032,
                                  color: const Color(0xFF00695C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // İçerik
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        child: ListView.builder(
                          itemCount: speakers.length,
                          itemBuilder: (context, index) {
                            final speaker = speakers[index];
                            return AICard(
                              title: speaker['title']!,
                              person: speaker['person']!,
                              initialTime: speaker['time']!,
                              backgroundColor: Color(int.parse(speaker['color']!)),
                              borderColor: Color(int.parse(speaker['color']!)),
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
          ),
          AppFooter(activeTab: "YÖNETİM"),
        ],
      ),
    );
  }
}

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
    // Zaman formatını parse etme (HH:MM:SS)
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
              '${widget.number}. KONUŞMACI BİLGİSİ',
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