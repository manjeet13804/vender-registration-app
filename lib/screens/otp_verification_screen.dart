import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vendor_provider.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  static const routeName = '/otp-verification';
  final String mobileNumber;
  final bool isRegistration;

  const OtpVerificationScreen({
    Key? key,
    required this.mobileNumber,
    this.isRegistration = false,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendTimer = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      await vendorProvider.verifyOtp(widget.mobileNumber, _otpController.text);
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verified successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login screen after successful verification
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    } catch (error) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendTimer > 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      await vendorProvider.resendOtp(widget.mobileNumber);
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully'),
        ),
      );
      
      _startResendTimer();
    } catch (error) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter OTP',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please enter the verification code sent to\n+91 ${widget.mobileNumber}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                hintText: '6-digit code',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Verify OTP'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendTimer > 0 || _isLoading ? null : _resendOtp,
              child: Text(
                _resendTimer > 0
                    ? 'Resend OTP in $_resendTimer seconds'
                    : 'Resend OTP',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
