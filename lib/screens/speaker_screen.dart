import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'management.dart';

class SpeakerScreen extends StatefulWidget {
  const SpeakerScreen({Key? key}) : super(key: key);

  @override
  State<SpeakerScreen> createState() => _SpeakerScreenState();
}

class _SpeakerScreenState extends State<SpeakerScreen> {
  List<Map<String, dynamic>> _speakers = [
    {
      'department': 'Satış ve Pazarlama Müdürü',
      'name': 'Macit AHISKALI',
      'time': '00:30:00',
      'isActive': true,
      'borderColor': const Color(0xFF5E6676),
    },
    {
      'department': 'Satış ve Pazarlama Müdürü',
      'name': 'Macit AHISKALI',
      'time': '00:30:00',
      'isActive': false,
      'borderColor': const Color(0xFFA24D00),
    },
  ];

  void _addSpeaker() {
    setState(() {
      _speakers.add({
        'department': 'Bölüm/Departman',
        'name': 'Ad Soyad',
        'time': '00:30:00',
        'isActive': false,
        'borderColor': const Color(0xFF5E6676),
      });
    });
  }

  void _toggleSpeaker(int index) {
    setState(() {
      _speakers[index]['isActive'] = !_speakers[index]['isActive'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    final isimlikWidth = isTablet ? 747.0 : screenWidth * 0.98;
    final containerHeight = isTablet
        ? (screenHeight > 772 ? 772.0 : screenHeight * 0.95)
        : screenHeight * 0.98;

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: isTablet
          ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Container(
              width: isimlikWidth,
              height: containerHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFFCFDFD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00D0C6),
                  width: 0.3,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isTablet),
                  Flexible(
                    child: _buildContent(isTablet),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Container(
                height: containerHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
                ),
                child: const ContentManagement(),
              ),
            ),
          ],
        ),
      )
          : Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isimlikWidth,
              maxHeight: containerHeight,
            ),
            width: isimlikWidth,
            height: containerHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFCFDFD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF00D0C6),
                width: 0.3,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isTablet),
                Flexible(
                  child: _buildContent(isTablet),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      height: isTablet ? 59 : 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFD0F9F9),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00D0C6),
            width: 0.3, 
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 13 : 10,
          vertical: isTablet ? 10 : 8,
        ),
        child: Row(
          children: [
            
            _buildLogo(isTablet),
            SizedBox(width: isTablet ? 9 : 6),
            
            Text(
              'İSİMLİK EKRANI',
              style: TextStyle(
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1D7269),
                height: 0.7,
              ),
            ),
            const Spacer(),
            
            _buildAddButton(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(bool isTablet) {
    return Container(
      width: isTablet ? 64 : 48,
      height: isTablet ? 24 : 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'LOGO',
          style: TextStyle(
            fontSize: isTablet ? 10 : 8,
            color: const Color(0xFF1D7269),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(bool isTablet) {
    return GestureDetector(
      onTap: _addSpeaker,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 6 : 5,
          vertical: isTablet ? 5 : 4,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFF469088),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'İSİM EKLE',
              style: TextStyle(
                fontSize: isTablet ? 15.2 : 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF0D7066),
                height: 0.92,
              ),
            ),
            SizedBox(width: isTablet ? 7 : 5),
            Icon(
              Icons.add,
              size: isTablet ? 19 : 15,
              color: const Color(0xFF0D7066),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 0 : 5),
      child: _speakers.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Konuşmacı bulunamadı',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      )
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int index = 0; index < _speakers.length; index++) ...[
            _buildSpeakerCard(
              _speakers[index],
              index,
              isTablet,
            ),
            
            if (index < _speakers.length - 1)
              Transform.translate(
                offset: Offset(0, isTablet ? -5.0 : -4.0),
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isTablet ? 13 : 8,
                  ),
                  height: 0,
                  width: isTablet ? 711.0 : double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFF00D0C6),
                        width: 1.5, 
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeakerCard(
      Map<String, dynamic> speaker,
      int index,
      bool isTablet,
      ) {
    
    final cardHeight = isTablet ? 210.0 : 180.0;

    return Container(
      margin: EdgeInsets.only(
        left: isTablet ? 13 : 8,
        right: isTablet ? 13 : 8,
        top: isTablet ? (index == 0 ? 11 : 0) : (index == 0 ? 8 : 0),
        bottom: 0,
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          
          Container(
            width: double.infinity, 
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: speaker['borderColor'] as Color,
                width: 0.3, 
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Expanded(
                  flex: isTablet ? 520 : 3,
                  child: _buildLeftSection(speaker, index, isTablet),
                ),
                
                if (isTablet)
                  _buildRightSection(index, isTablet, speaker['borderColor'] as Color)
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
          
          Positioned(
            left: isTablet ? 22.0 : 15.0,
            top: -8.0,
            child: _buildSpeakerBadgeWithBorder(index + 1, isTablet, speaker['borderColor'] as Color),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSection(
      Map<String, dynamic> speaker,
      int index,
      bool isTablet,
      ) {
    
    return SizedBox(
      width: isTablet ? 520.0 : double.infinity,
      height: isTablet ? 210.0 : 180.0,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          
          Positioned(
            left: isTablet ? 32.0 : 15.0,
            top: isTablet ? 32.0 : 25.0,
            child: _buildIcon(Icons.description, isTablet ? 20 : 18, isTablet ? 16 : 14),
          ),
          
          Positioned(
            left: isTablet ? 61.0 : 50.0,
            top: isTablet ? 32.0 : 25.0,
            child: SizedBox(
              width: isTablet ? 300.0 : 200.0,
              height: isTablet ? 18.0 : 16.0,
              child: Text(
                speaker['department'] as String,
                style: TextStyle(
                  fontSize: isTablet ? 20.0 : 16,
                  fontWeight: FontWeight.w400,
                  color: speaker['borderColor'] == const Color(0xFF5E6676)
                      ? const Color(0xFF414A5D)
                      : const Color(0xFFA24D00),
                  height: 0.94,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          Positioned(
            left: isTablet ? 32.0 : 15.0,
            top: isTablet ? 75.0 : 60.0,
            child: _buildIcon(Icons.person, isTablet ? 20 : 18, isTablet ? 22 : 20),
          ),
          
          Positioned(
            left: isTablet ? 61.0 : 50.0,
            top: isTablet ? 75.0 : 60.0,
            child: SizedBox(
              width: isTablet ? 170.0 : 150.0,
              height: isTablet ? 22.0 : 20.0,
              child: Text(
                speaker['name'] as String,
                style: TextStyle(
                  fontSize: isTablet ? 20.0 : 16,
                  fontWeight: FontWeight.w400,
                  color: speaker['borderColor'] == const Color(0xFF5E6676)
                      ? const Color(0xFF414A5D)
                      : const Color(0xFFA24D00),
                  height: 0.94,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          Positioned(
            left: isTablet ? 32.0 : 15.0,
            top: isTablet ? 118.0 : 95.0,
            child: _buildIcon(Icons.timer, isTablet ? 20 : 18, isTablet ? 22 : 20),
          ),
          
          Positioned(
            left: isTablet ? 61.0 : 50.0,
            top: isTablet ? 118.0 : 95.0,
            child: SizedBox(
              width: isTablet ? 130.0 : 120.0,
              height: isTablet ? 20.0 : 18.0,
              child: _buildDigitalTime(
                speaker['time'] as String,
                speaker['borderColor'] == const Color(0xFF5E6676)
                    ? const Color(0xFF3B4458)
                    : const Color(0xFFA24D00),
                isTablet,
              ),
            ),
          ),
          
          Positioned(
            left: isTablet ? 420.0 : 200.0,
            top: isTablet ? 125.0 : 100.0,
            child: _buildToggleSwitch(
              speaker['isActive'] as bool,
              index,
              isTablet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalTime(String time, Color textColor, bool isTablet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < time.length; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: time[i] == ':' ? 2.0 : 1.0),
            child: Text(
              time[i],
              style: TextStyle(
                fontSize: isTablet ? 28.0 : 24,
                fontWeight: FontWeight.w400,
                fontFamily: 'monospace',
                color: textColor,
                height: 0.70,
                letterSpacing: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSpeakerBadgeWithBorder(int number, bool isTablet, Color borderColor) {
    final fontSize = isTablet ? 13.5 : 11.0;
    final verticalPadding = isTablet ? 3.0 : 2.0;
    final textHeight = fontSize * 1.037037037037037;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        
        Positioned(
          left: -300,
          right: -300,
          top: (textHeight / 2) + verticalPadding,
          child: Container(
            height: 0.3,
            color: borderColor,
          ),
        ),
        
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 8 : 6,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            '$number. KONUŞMACI BİLGİSİ',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF3B4458),
              height: 1.037037037037037,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(IconData icon, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Icon(
        icon,
        size: width * 0.6,
        color: const Color(0xFF3C465A),
      ),
    );
  }

  Widget _buildToggleSwitch(bool isActive, int index, bool isTablet) {
    return GestureDetector(
      onTap: () => _toggleSpeaker(index),
      child: Container(
        width: isTablet ? 35 : 30,
        height: isTablet ? 16 : 14,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF196E64) : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Align(
          alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: isTablet ? 12 : 10,
            height: isTablet ? 12 : 10,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightSection(int index, bool isTablet, Color borderColor) {
    
    

    return Container(
      width: isTablet ? 191 : 0,
      height: isTablet ? 210 : 0,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 0,
        vertical: isTablet ? 20 : 0,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Container(
                width: 78,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFF9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  border: Border.all(
                    color: const Color(0xFF52596C),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: isTablet ? 22 : 20,
                    color: const Color(0xFF3B4458),
                  ),
                ),
              ),
              
              Container(
                width: 78,
                height: 87,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFF9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  border: Border.all(
                    color: const Color(0xFF52596C),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.remove,
                    size: isTablet ? 22 : 20,
                    color: const Color(0xFF3B4458),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: isTablet ? 13 : 8), 
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Container(
                width: 78,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5), 
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF52596C),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.close,
                    size: isTablet ? 22 : 20,
                    color: Colors.red[700],
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 3 : 2),

              Container(
                width: 78,
                height: 87,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF52596C),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow,
                    size: isTablet ? 22 : 20,
                    color: const Color(0xFF3B4458),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}