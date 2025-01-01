import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vendor_provider.dart';
import 'registration_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOtpLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      
      if (_isOtpLogin) {
        await vendorProvider.sendOtp(_mobileController.text);
        
        if (!mounted) return;
        
        final verified = await Navigator.of(context).pushNamed(
          OtpVerificationScreen.routeName,
          arguments: {
            'mobileNumber': _mobileController.text,
            'isRegistration': false,
          },
        );

        if (verified == true) {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        await vendorProvider.login(
          _emailController.text,
          _passwordController.text,
        );
        
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 10),
                    Text(
                      'Vendor Login',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Toggle between email and OTP login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Email Login'),
                      selected: !_isOtpLogin,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _isOtpLogin = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('OTP Login'),
                      selected: _isOtpLogin,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _isOtpLogin = true;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isOtpLogin)
                  TextFormField(
                    controller: _mobileController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixText: '+91 ',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter mobile number';
                      }
                      if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'Please enter valid 10-digit mobile number';
                      }
                      return null;
                    },
                  )
                else ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      return null;
                    },
                  ),
                ],
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isOtpLogin ? 'Send OTP' : 'Login'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pushReplacementNamed(RegistrationScreen.routeName);
                  },
                  child: const Text('New Vendor? Register here'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
