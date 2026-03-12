import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'ai_page.dart';
import 'chat_page.dart';
import 'map_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0;

  static const _tabs = <Widget>[
    _HomeTab(),
    MapPage(),
    ChatPage(),
    AiPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _tabs[_currentTab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() => _currentTab = i),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primary),
            label: 'หน้าหลัก',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppTheme.primary),
            label: 'แผนที่',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: AppTheme.primary),
            label: 'แชท',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy, color: AppTheme.primary),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primary),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// HOME TAB — เนื้อหาหลัก
// ════════════════════════════════════════════════════════════════

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late final PageController _newsCtrl;
  int _newsPage = 0;

  @override
  void initState() {
    super.initState();
    _newsCtrl = PageController(viewportFraction: 0.85);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || !_newsCtrl.hasClients) return;
      final next = (_newsPage + 1) % _healthNews.length;
      _newsCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _newsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildSosButton(context),
          const SizedBox(height: 28),
          _buildSectionTitle('ข่าวสารสุขภาพ', Icons.newspaper),
          const SizedBox(height: 12),
          _buildNewsCarousel(),
          const SizedBox(height: 28),
          _buildSectionTitle('เบอร์โทรฉุกเฉิน', Icons.phone_in_talk),
          const SizedBox(height: 12),
          _buildEmergencyNumbers(context),
          const SizedBox(height: 28),
          _buildSectionTitle('ปฐมพยาบาลเบื้องต้น', Icons.medical_services),
          const SizedBox(height: 12),
          _buildQuickTips(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context) {
    final today = DateFormat('d MMM yyyy').format(DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safe Life',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'แอพช่วยชีวิต',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                today,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── SOS Button ──
  Widget _buildSosButton(BuildContext context) {
    return Center(child: _SosPulseButton(onTap: () => _callSos(context)));
  }

  Future<void> _callSos(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('เลือกวิธีขอความช่วยเหลือ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            _SosOptionCard(
              icon: Icons.phone_in_talk,
              title: 'โทร 1669 (สายด่วนการแพทย์)',
              color: AppTheme.primary,
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('tel:1669'));
              },
            ),
            const SizedBox(height: 12),
            _SosOptionCard(
              icon: Icons.chat,
              title: 'ส่งข้อความเข้า LINE',
              subtitle: 'พร้อมพิกัด GPS ปัจจุบัน',
              color: const Color(0xFF00B900),
              onTap: () {
                Navigator.pop(ctx);
                _sendEmergencyLine(context);
              },
            ),
            const SizedBox(height: 12),
            _SosOptionCard(
              icon: Icons.sms,
              title: 'ส่ง SMS หาคนสนิท',
              subtitle: 'ส่งพิกัดไปเบอร์ฉุกเฉินที่ตั้งไว้',
              color: AppTheme.warning,
              onTap: () {
                Navigator.pop(ctx);
                _sendEmergencySms(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ));
  }

  Future<void> _sendEmergencyLine(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('กำลังดึงพิกัด GPS...')),
    );
    
    final pos = await _getCurrentLocation();
    String message = '🚨 SOS ฉุกเฉิน! ฉันต้องการความช่วยเหลือด่วน\n';
    
    if (pos != null) {
      message += 'พิกัดของฉัน: https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
    } else {
      message += '(ไม่สามารถดึงพิกัดได้)';
    }

    final url = Uri.parse('https://line.me/R/share?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบแอป LINE ในเครื่อง')),
        );
      }
    }
  }

  Future<void> _sendEmergencySms(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('กำลังดึงข้อมูลและเตรียมส่ง SMS...')),
    );

    // Get contacts
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('emergency_contacts')
        .get();

    final phones = snapshot.docs.map((d) => d['phone'] as String).toList();
    if (phones.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยังไม่มีเบอร์ฉุกเฉิน กรุณาไปเพิ่มที่หน้าโปรไฟล์')),
        );
      }
      return;
    }

    final pos = await _getCurrentLocation();
    String message = '🚨 SOS ฉุกเฉินจาก ${user.displayName ?? 'ผู้ใช้งาน SafeLife'}!\nช่วยด้วย!';
    if (pos != null) {
      message += '\nพิกัด: https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
    }

    // Send SMS
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phones.join(','),
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เปิดแอปสำหรับส่ง SMS เรียบร้อยแล้ว'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเปิดแอปข้อความ (SMS) ได้')),
        );
      }
    }
  }

  // ── Section Title ──
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── News Carousel ──
  Widget _buildNewsCarousel() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _newsCtrl,
        itemCount: _healthNews.length,
        onPageChanged: (i) => setState(() => _newsPage = i),
        itemBuilder: (context, i) {
          final news = _healthNews[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(news.url),
                mode: LaunchMode.externalApplication,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: news.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: news.colors[0].withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(news.icon, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            news.source,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Text(
                        news.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Text(
                          'อ่านต่อ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Emergency Numbers ──
  Widget _buildEmergencyNumbers(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _emergencyNumbers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final em = _emergencyNumbers[i];
          return GestureDetector(
            onTap: () => _confirmCall(context, em),
            child: Container(
              width: 110,
              decoration: BoxDecoration(
                color: em.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: em.color.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(em.icon, color: em.color, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    em.number,
                    style: TextStyle(
                      color: em.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    em.label,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmCall(BuildContext context, _EmergencyNum em) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(em.icon, color: em.color),
            const SizedBox(width: 8),
            Text(em.label),
          ],
        ),
        content: Text('โทรหา ${em.label} (${em.number})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('โทร'),
            style: ElevatedButton.styleFrom(
              backgroundColor: em.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      launchUrl(Uri.parse('tel:${em.number}'));
    }
  }

  // ── Quick Tips ──
  Widget _buildQuickTips() {
    return Column(
      children: _quickTips.map((tip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tip.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tip.icon, color: tip.color, size: 24),
              ),
              title: Text(
                tip.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  tip.desc,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SosOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SosOptionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SOS PULSE BUTTON — heartbeat animation
// ════════════════════════════════════════════════════════════════

class _SosPulseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SosPulseButton({required this.onTap});

  @override
  State<_SosPulseButton> createState() => _SosPulseButtonState();
}

class _SosPulseButtonState extends State<_SosPulseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scale = Tween(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 180,
        height: 180,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulse ring
                Transform.scale(
                  scale: _scale.value * 1.1,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(
                        alpha: _opacity.value * 0.3,
                      ),
                    ),
                  ),
                ),
                // Inner pulse ring
                Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(
                        alpha: _opacity.value * 0.5,
                      ),
                    ),
                  ),
                ),
                // Main button
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.accent, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sos, color: Colors.white, size: 40),
                      SizedBox(height: 4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// DATA MODELS
// ════════════════════════════════════════════════════════════════

class _NewsItem {
  final String title;
  final String source;
  final String url;
  final IconData icon;
  final List<Color> colors;

  const _NewsItem({
    required this.title,
    required this.source,
    required this.url,
    required this.icon,
    required this.colors,
  });
}

class _EmergencyNum {
  final String number;
  final String label;
  final IconData icon;
  final Color color;

  const _EmergencyNum({
    required this.number,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _TipItem {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  const _TipItem({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
  });
}

// ════════════════════════════════════════════════════════════════
// STATIC DATA
// ════════════════════════════════════════════════════════════════

const _healthNews = [
  _NewsItem(
    title: 'วิธีทำ CPR ที่ถูกต้อง ช่วยชีวิตคนใกล้ตัวได้ทันเวลา',
    source: 'สภากาชาดไทย',
    url: 'https://www.redcross.or.th',
    icon: Icons.favorite,
    colors: [Color(0xFFE53935), Color(0xFFEF5350)],
  ),
  _NewsItem(
    title: 'รู้ทันโรคหัวใจ: สัญญาณเตือนที่ไม่ควรมองข้าม',
    source: 'กรมควบคุมโรค',
    url: 'https://ddc.moph.go.th',
    icon: Icons.monitor_heart,
    colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
  ),
  _NewsItem(
    title: 'Heat Stroke ภัยร้ายหน้าร้อน วิธีป้องกันและดูแลเบื้องต้น',
    source: 'กระทรวงสาธารณสุข',
    url: 'https://www.moph.go.th',
    icon: Icons.wb_sunny,
    colors: [Color(0xFFFF8F00), Color(0xFFFFA726)],
  ),
  _NewsItem(
    title: 'การปฐมพยาบาลเมื่อถูกสัตว์มีพิษกัด',
    source: 'ศิริราช',
    url: 'https://www.si.mahidol.ac.th',
    icon: Icons.healing,
    colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
  ),
  _NewsItem(
    title: 'เตรียมตัวรับมือภัยพิบัติ: สิ่งที่ต้องมีในกระเป๋าฉุกเฉิน',
    source: 'กรมป้องกันและบรรเทาสาธารณภัย',
    url: 'https://www.disaster.go.th',
    icon: Icons.backpack,
    colors: [Color(0xFF00897B), Color(0xFF26A69A)],
  ),
];

const _emergencyNumbers = [
  _EmergencyNum(
    number: '1669',
    label: 'การแพทย์',
    icon: Icons.local_hospital,
    color: Color(0xFFE53935),
  ),
  _EmergencyNum(
    number: '191',
    label: 'ตำรวจ',
    icon: Icons.local_police,
    color: Color(0xFF1565C0),
  ),
  _EmergencyNum(
    number: '199',
    label: 'ดับเพลิง',
    icon: Icons.fire_truck,
    color: Color(0xFFFF8F00),
  ),
  _EmergencyNum(
    number: '1323',
    label: 'สุขภาพจิต',
    icon: Icons.psychology,
    color: Color(0xFF7B1FA2),
  ),
  _EmergencyNum(
    number: '1584',
    label: 'ท่องเที่ยว',
    icon: Icons.travel_explore,
    color: Color(0xFF00897B),
  ),
];

const _quickTips = [
  _TipItem(
    title: 'CPR เบื้องต้น',
    desc: 'กดหน้าอกลึก 5 ซม. อัตรา 100-120 ครั้ง/นาที ช่วยผู้ที่หัวใจหยุดเต้น',
    icon: Icons.favorite,
    color: Color(0xFFE53935),
  ),
  _TipItem(
    title: 'ห้ามเลือด',
    desc: 'กดแผลด้วยผ้าสะอาด ยกส่วนที่เลือดออกให้สูง อย่าดึงผ้าออก',
    icon: Icons.water_drop,
    color: Color(0xFFC62828),
  ),
  _TipItem(
    title: 'กรณีชัก',
    desc: 'ไม่สอดนิ้วหรือสิ่งของเข้าปาก จับตะแคง รอจนหยุดชัก แล้วโทร 1669',
    icon: Icons.warning_amber,
    color: Color(0xFFFF8F00),
  ),
  _TipItem(
    title: 'แพ้อาหารรุนแรง',
    desc: 'ถ้ามีอาการบวมที่ใบหน้า หายใจลำบาก ให้โทร 1669 ทันที',
    icon: Icons.no_food,
    color: Color(0xFF7B1FA2),
  ),
];
