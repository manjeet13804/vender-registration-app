import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendor_registration_app/providers/vendor_provider.dart';
import 'package:vendor_registration_app/screens/login_screen.dart';
import 'package:vendor_registration_app/screens/registration_screen.dart';
import 'package:vendor_registration_app/screens/otp_verification_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => VendorProvider(),
      child: MaterialApp(
        title: 'Indiazona Vendor Registration',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF2F54EB),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2F54EB),
            primary: const Color(0xFF2F54EB),
            secondary: Colors.orange,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2F54EB), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F54EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2F54EB),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textTheme: const TextTheme(
            headlineSmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F54EB),
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        initialRoute: LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (ctx) => const LoginScreen(),
          RegistrationScreen.routeName: (ctx) => const RegistrationScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == OtpVerificationScreen.routeName) {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                mobileNumber: args['mobileNumber'] as String,
                isRegistration: args['isRegistration'] as bool? ?? false,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}