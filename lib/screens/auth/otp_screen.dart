import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final bool isLogin;
  final String? qrCode;
  final String? secret;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.isLogin,
    this.qrCode,
    this.secret,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _showQR = true;

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP daalo!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.verifyOTP(
          widget.phone, _otpController.text.trim());
      await ApiService.saveToken(response.data['token']);
      await ApiService.saveUser(response.data['user']);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP! Dobara try karo')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        title: Text(widget.isLogin ? 'Login OTP' : 'Setup Authenticator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 60, color: Color(0xFF0084FF)),
            const SizedBox(height: 16),
            Text(
              widget.isLogin ? 'Google Authenticator OTP' : 'Setup Google Authenticator',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.isLogin
                  ? 'Google Authenticator app mein NexChat ka 6 digit code daalo'
                  : 'Pehle Google Authenticator install karo, phir QR scan karo',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Show QR only for registration
            if (!widget.isLogin && widget.qrCode != null) ...[
              if (_showQR) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF0084FF), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.memory(
                    base64Decode(widget.qrCode!.split(',')[1]),
                    width: 200,
                    height: 200,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Ya manually enter karo:',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                SelectableText(
                  widget.secret ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showQR = !_showQR),
                child: Text(_showQR ? 'QR hide karo' : 'QR show karo'),
              ),
            ],

            const SizedBox(height: 24),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: '6 digit OTP',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF0084FF), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify & Login',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
