import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  DateTime? _dob;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  // ── Validators ──

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'กรุณากรอก Username';
    if (v.trim().length < 4) return 'Username ต้องมีอย่างน้อย 4 ตัวอักษร';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
      return 'ใช้ได้เฉพาะ a-z, 0-9 และ _ เท่านั้น';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9) return 'เบอร์โทรต้องมี 9 หลัก (ไม่รวม +66)';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (v.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'ต้องมีตัวพิมพ์ใหญ่อย่างน้อย 1 ตัว';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'ต้องมีตัวพิมพ์เล็กอย่างน้อย 1 ตัว';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'ต้องมีตัวเลขอย่างน้อย 1 ตัว';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordCtrl.text) return 'รหัสผ่านไม่ตรงกัน';
    return null;
  }

  // ── Date Picker ──

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 18),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppTheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  // ── Sign Up ──

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      _showSnack('กรุณาเลือกวันเดือนปีเกิด');
      return;
    }

    setState(() => _loading = true);

    try {
      final username = _usernameCtrl.text.trim().toLowerCase();

      // ตรวจ username ซ้ำ
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _showSnack('Username นี้ถูกใช้แล้ว');
        return;
      }

      // สร้าง Firebase Auth user ด้วย email จาก username
      final email = '$username@safelife.app';
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordCtrl.text,
      );

      // บันทึก profile ลง Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'username': username,
        'phone': '+66${_phoneCtrl.text.trim()}',
        'dob': Timestamp.fromDate(_dob!),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await cred.user!.updateDisplayName(username);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'เกิดข้อผิดพลาด');
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Logo / Header
                  Icon(Icons.health_and_safety,
                      size: 64, color: AppTheme.primary),
                  const SizedBox(height: 8),
                  Text('สร้างบัญชี',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text('SafeLife — แอพช่วยชีวิต',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),

                  // Username
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _validateUsername,
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'วันเดือนปีเกิด',
                          prefixIcon: const Icon(Icons.cake_outlined),
                          suffixIcon: const Icon(Icons.calendar_today, size: 20),
                        ),
                        controller: TextEditingController(
                          text: _dob != null
                              ? DateFormat('dd/MM/yyyy').format(_dob!)
                              : '',
                        ),
                        validator: (_) =>
                            _dob == null ? 'กรุณาเลือกวันเดือนปีเกิด' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'เบอร์โทรศัพท์',
                      prefixIcon: Icon(Icons.phone_outlined),
                      prefixText: '+66 ',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    textInputAction: TextInputAction.next,
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    obscureText: _obscurePass,
                    textInputAction: TextInputAction.next,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmCtrl,
                    decoration: InputDecoration(
                      labelText: 'ยืนยันรหัสผ่าน',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    validator: _validateConfirm,
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  _loading
                      ? const CircularProgressIndicator(color: AppTheme.primary)
                      : ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.person_add),
                          label: const Text('สร้างบัญชี'),
                        ),
                  const SizedBox(height: 16),

                  // Go to Sign-in
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('มีบัญชีอยู่แล้ว? '),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/signin'),
                        child: Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
