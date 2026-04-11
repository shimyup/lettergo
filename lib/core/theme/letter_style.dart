import 'package:flutter/material.dart';

String _t14(Map<String, String> m, String lc) => m[lc] ?? m['en'] ?? '';

/// 편지지 스타일 정의 (5종 무료, 이후 유료 추가 예정)
class PaperStyle {
  final String name;
  final Map<String, String> _nameL;
  final Color bgColor;
  final Color lineColor;
  final bool hasLines;
  final bool hasDots;
  final Color inkColor;
  final String emoji;
  const PaperStyle({
    required this.name,
    Map<String, String> nameL = const {},
    required this.bgColor,
    required this.lineColor,
    required this.hasLines,
    required this.hasDots,
    required this.inkColor,
    required this.emoji,
  }) : _nameL = nameL;

  String localizedName(String lc) =>
      _nameL.isNotEmpty ? _t14(_nameL, lc) : name;
}

/// 폰트 스타일 정의
class FontStyleConfig {
  final String name;
  final Map<String, String> _nameL;
  final TextStyle textStyle;
  final String emoji;
  const FontStyleConfig({
    required this.name,
    Map<String, String> nameL = const {},
    required this.textStyle,
    required this.emoji,
  }) : _nameL = nameL;

  String localizedName(String lc) =>
      _nameL.isNotEmpty ? _t14(_nameL, lc) : name;
}

class LetterStyles {
  static const List<PaperStyle> papers = [
    PaperStyle(
      name: 'Classic Cream',
      nameL: {'ko': '클래식 크림', 'en': 'Classic Cream', 'ja': 'クラシッククリーム', 'zh': '经典奶油', 'fr': 'Crème Classique', 'de': 'Klassisch Creme', 'es': 'Crema Clásico', 'pt': 'Creme Clássico', 'ru': 'Классический крем', 'tr': 'Klasik Krem', 'ar': 'كريم كلاسيكي', 'it': 'Crema Classico', 'hi': 'क्लासिक क्रीम', 'th': 'ครีมคลาสสิก'},
      bgColor: Color(0xFFFDF6E3),
      lineColor: Color(0xFFD4C5A9),
      hasLines: false,
      hasDots: false,
      inkColor: Color(0xFF2C1810),
      emoji: '📄',
    ),
    PaperStyle(
      name: 'Blue Lines',
      nameL: {'ko': '블루 라인', 'en': 'Blue Lines', 'ja': 'ブルーライン', 'zh': '蓝色线条', 'fr': 'Lignes Bleues', 'de': 'Blaue Linien', 'es': 'Líneas Azules', 'pt': 'Linhas Azuis', 'ru': 'Голубые линии', 'tr': 'Mavi Çizgiler', 'ar': 'خطوط زرقاء', 'it': 'Linee Blu', 'hi': 'ब्लू लाइन', 'th': 'เส้นสีฟ้า'},
      bgColor: Color(0xFFF0F6FF),
      lineColor: Color(0xFFB0C8F0),
      hasLines: true,
      hasDots: false,
      inkColor: Color(0xFF1A2C4E),
      emoji: '📋',
    ),
    PaperStyle(
      name: 'Vintage Parchment',
      nameL: {'ko': '빈티지 양피지', 'en': 'Vintage Parchment', 'ja': 'ヴィンテージ羊皮紙', 'zh': '复古羊皮纸', 'fr': 'Parchemin Vintage', 'de': 'Vintage Pergament', 'es': 'Pergamino Vintage', 'pt': 'Pergaminho Vintage', 'ru': 'Винтажный пергамент', 'tr': 'Vintage Parşömen', 'ar': 'رق عتيق', 'it': 'Pergamena Vintage', 'hi': 'विंटेज पार्चमेंट', 'th': 'กระดาษหนังวินเทจ'},
      bgColor: Color(0xFFEDD9A3),
      lineColor: Color(0xFFC4A96A),
      hasLines: false,
      hasDots: true,
      inkColor: Color(0xFF3B2A1A),
      emoji: '📜',
    ),
    PaperStyle(
      name: 'Deep Ocean (Dark)',
      nameL: {'ko': '깊은 바다 (다크)', 'en': 'Deep Ocean (Dark)', 'ja': '深海（ダーク）', 'zh': '深海（暗色）', 'fr': 'Océan Profond (Sombre)', 'de': 'Tiefsee (Dunkel)', 'es': 'Océano Profundo (Oscuro)', 'pt': 'Oceano Profundo (Escuro)', 'ru': 'Глубокий океан (тёмный)', 'tr': 'Derin Okyanus (Koyu)', 'ar': 'محيط عميق (داكن)', 'it': 'Oceano Profondo (Scuro)', 'hi': 'गहरा सागर (डार्क)', 'th': 'มหาสมุทรลึก (มืด)'},
      bgColor: Color(0xFF0D1B2A),
      lineColor: Color(0xFF1E3A52),
      hasLines: true,
      hasDots: false,
      inkColor: Color(0xFFE0F0FF),
      emoji: '🌊',
    ),
    PaperStyle(
      name: 'Spring Dots',
      nameL: {'ko': '봄날 도트', 'en': 'Spring Dots', 'ja': '春のドット', 'zh': '春日圆点', 'fr': 'Points Printaniers', 'de': 'Frühlingspunkte', 'es': 'Puntos de Primavera', 'pt': 'Pontos de Primavera', 'ru': 'Весенние точки', 'tr': 'Bahar Noktaları', 'ar': 'نقاط الربيع', 'it': 'Punti Primaverili', 'hi': 'स्प्रिंग डॉट्स', 'th': 'จุดฤดูใบไม้ผลิ'},
      bgColor: Color(0xFFF5FFF0),
      lineColor: Color(0xFFB8E8A0),
      hasLines: false,
      hasDots: true,
      inkColor: Color(0xFF2A4A1E),
      emoji: '🌸',
    ),
  ];

  static const List<FontStyleConfig> fonts = [
    FontStyleConfig(
      name: 'Default',
      nameL: {'ko': '기본', 'en': 'Default', 'ja': 'デフォルト', 'zh': '默认', 'fr': 'Par défaut', 'de': 'Standard', 'es': 'Predeterminado', 'pt': 'Padrão', 'ru': 'По умолчанию', 'tr': 'Varsayılan', 'ar': 'افتراضي', 'it': 'Predefinito', 'hi': 'डिफ़ॉल्ट', 'th': 'ค่าเริ่มต้น'},
      emoji: 'A',
      textStyle: TextStyle(
        fontSize: 16,
        height: 1.85,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w400,
      ),
    ),
    FontStyleConfig(
      name: 'Serif',
      nameL: {'ko': '세리프', 'en': 'Serif', 'ja': 'セリフ', 'zh': '衬线', 'fr': 'Serif', 'de': 'Serif', 'es': 'Serif', 'pt': 'Serifado', 'ru': 'С засечками', 'tr': 'Serif', 'ar': 'مذيّل', 'it': 'Serif', 'hi': 'सेरिफ़', 'th': 'เซริฟ'},
      emoji: 'Ã',
      textStyle: TextStyle(
        fontSize: 15,
        height: 1.9,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.normal,
        fontFamily: 'serif',
      ),
    ),
    FontStyleConfig(
      name: 'Typewriter',
      nameL: {'ko': '타자기', 'en': 'Typewriter', 'ja': 'タイプライター', 'zh': '打字机', 'fr': 'Machine à écrire', 'de': 'Schreibmaschine', 'es': 'Máquina de escribir', 'pt': 'Máquina de escrever', 'ru': 'Печатная машинка', 'tr': 'Daktilo', 'ar': 'آلة كاتبة', 'it': 'Macchina da scrivere', 'hi': 'टाइपराइटर', 'th': 'พิมพ์ดีด'},
      emoji: '⌨',
      textStyle: TextStyle(
        fontSize: 14,
        height: 1.95,
        letterSpacing: 1.0,
        fontFamily: 'Courier',
        fontWeight: FontWeight.w400,
      ),
    ),
    FontStyleConfig(
      name: 'Handwritten',
      nameL: {'ko': '손글씨', 'en': 'Handwritten', 'ja': '手書き', 'zh': '手写', 'fr': 'Manuscrit', 'de': 'Handschrift', 'es': 'Manuscrito', 'pt': 'Manuscrito', 'ru': 'Рукописный', 'tr': 'El Yazısı', 'ar': 'خط يد', 'it': 'Scritto a mano', 'hi': 'हस्तलिखित', 'th': 'ลายมือ'},
      emoji: '✍',
      textStyle: TextStyle(
        fontSize: 16,
        height: 2.0,
        letterSpacing: 0.8,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w300,
      ),
    ),
  ];

  static PaperStyle paper(int index) =>
      papers[index.clamp(0, papers.length - 1)];
  static FontStyleConfig font(int index) =>
      fonts[index.clamp(0, fonts.length - 1)];
}

/// 편지지 배경 커스텀 페인터
class LetterPaperPainter extends CustomPainter {
  final PaperStyle style;
  const LetterPaperPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    // 배경색
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = style.bgColor,
    );
    if (style.hasLines) {
      final paint = Paint()
        ..color = style.lineColor
        ..strokeWidth = 0.8;
      double y = 40;
      while (y < size.height) {
        canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);
        y += 32;
      }
    }
    if (style.hasDots) {
      final paint = Paint()
        ..color = style.lineColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.fill;
      double y = 36;
      while (y < size.height) {
        double x = 24;
        while (x < size.width - 16) {
          canvas.drawCircle(Offset(x, y), 1.2, paint);
          x += 28;
        }
        y += 28;
      }
    }
  }

  @override
  bool shouldRepaint(LetterPaperPainter old) => old.style != style;
}
