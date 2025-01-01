import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show Platform;

class VendorProvider with ChangeNotifier {
  String? _token;
  List<Vendor> _vendors = [];
  String? _lastErrorMessage;

  String? get lastErrorMessage => _lastErrorMessage;

  // Base URLs for different environments
  final List<String> _baseUrls = [
    'http://localhost:5000',
    'http://10.0.2.2:5000', // Android emulator localhost
    'https://vendor-registration-api-wduz.onrender.com',
  ];

  String get baseUrl {
    if (kIsWeb || Platform.isWindows) {
      return _baseUrls[0]; // Use localhost for web and Windows
    }
    return _baseUrls[1]; // Use 10.0.2.2 for Android emulator
  }

  List<Vendor> get vendors => _vendors;
  bool get isAuthenticated => _token != null;

  // Helper method to try both URLs
  Future<http.Response> _makeRequest(
    String endpoint,
    String method,
    Map<String, dynamic>? body,
    Map<String, String> headers,
  ) async {
    headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });

    String? lastErrorMessage;
    for (String baseUrl in _baseUrls) {
      try {
        final url = Uri.parse('$baseUrl/api$endpoint');
        print('Trying URL: $url'); // Debug log
        
        http.Response response;
        switch (method) {
          case 'POST':
            response = await http.post(
              url,
              body: json.encode(body),
              headers: headers,
            ).timeout(const Duration(seconds: 30));
            break;
          case 'GET':
            response = await http.get(url, headers: headers)
                .timeout(const Duration(seconds: 30));
            break;
          default:
            throw Exception('Unsupported HTTP method');
        }

        print('Response status: ${response.statusCode}'); // Debug log
        print('Response body: ${response.body}'); // Debug log

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        } 
        
        // Parse error message from response
        Map<String, dynamic> errorData;
        try {
          errorData = json.decode(response.body);
        } catch (e) {
          errorData = {'message': response.body};
        }
        
        throw Exception(
          errorData['message'] ?? 'Request failed with status: ${response.statusCode}',
        );
      } catch (e) {
        print('Error making request to $baseUrl: $e');
        lastErrorMessage = e.toString();
        // Continue to next URL only for connection errors
        if (e is! http.ClientException && e is! TimeoutException) {
          rethrow;
        }
      }
    }
    throw Exception(lastErrorMessage ?? 'Failed to connect to server');
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _makeRequest(
        '/auth/login',
        'POST',
        {
          'email': email,
          'password': password,
        },
        {},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _token = responseData['token'];
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to log in');
      }
    } catch (error) {
      _lastErrorMessage = error.toString();
      throw Exception(_lastErrorMessage);
    }
  }

  Future<void> sendOtp(String mobileNumber) async {
    try {
      // Validate phone number format
      if (!mobileNumber.startsWith('+91')) {
        mobileNumber = '+91$mobileNumber';
      }
      
      if (!RegExp(r'^\+91[0-9]{10}$').hasMatch(mobileNumber)) {
        throw Exception('Invalid mobile number format');
      }

      final url = Uri.parse('$baseUrl/api/auth/send-otp'); // Fixed endpoint
      print('Sending OTP request to: $url'); // Debug log

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'mobileNumber': mobileNumber,
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode != 200) {
        Map<String, dynamic> errorData;
        try {
          errorData = json.decode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to send OTP');
        } catch (e) {
          throw Exception('Failed to send OTP: ${response.body}');
        }
      }
    } catch (error) {
      print('Error sending OTP: $error'); // Debug log
      _lastErrorMessage = error.toString();
      throw Exception(_lastErrorMessage);
    }
  }

  Future<void> resendOtp(String mobileNumber) async {
    return sendOtp(mobileNumber);
  }

  Future<void> registerVendor(
    String name,
    String email,
    String password,
    String mobileNumber, {
    String? referenceCode,
  }) async {
    try {
      // Validate phone number format
      if (!mobileNumber.startsWith('+91')) {
        mobileNumber = '+91$mobileNumber';
      }
      
      if (!RegExp(r'^\+91[0-9]{10}$').hasMatch(mobileNumber)) {
        throw Exception('Invalid mobile number format');
      }

      final body = {
        'name': name,
        'email': email,
        'password': password,
        'mobileNumber': mobileNumber,
        if (referenceCode != null) 'referenceCode': referenceCode,
      };

      final response = await _makeRequest(
        '/auth/register',
        'POST',
        body,
        {},
      );

      final responseData = json.decode(response.body);
      _token = responseData['token'];
      notifyListeners();
    } catch (error) {
      _lastErrorMessage = error.toString();
      throw Exception(_lastErrorMessage);
    }
  }

  void logout() {
    _token = null;
    _lastErrorMessage = null;
    notifyListeners();
  }

  Future<void> fetchVendors() async {
    try {
      final response = await _makeRequest(
        '/vendors',
        'GET',
        null,
        {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as List;
        _vendors = responseData.map((vendor) => Vendor.fromJson(vendor)).toList();
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch vendors');
      }
    } catch (error) {
      _lastErrorMessage = error.toString();
      throw Exception(_lastErrorMessage);
    }
  }

  Future<void> verifyOtp(String mobileNumber, String otp) async {
    try {
      // Validate phone number format
      if (!mobileNumber.startsWith('+91')) {
        mobileNumber = '+91$mobileNumber';
      }

      final url = Uri.parse('$baseUrl/api/auth/verify-otp'); // Fixed endpoint
      print('Sending verify OTP request to: $url'); // Debug log

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'mobileNumber': mobileNumber,
          'otp': otp,
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode != 200) {
        Map<String, dynamic> errorData;
        try {
          errorData = json.decode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to verify OTP');
        } catch (e) {
          throw Exception('Failed to verify OTP: ${response.body}');
        }
      }

      final responseData = json.decode(response.body);
      _token = responseData['token'];
      _lastErrorMessage = null;
      notifyListeners();
    } catch (error) {
      print('Error verifying OTP: $error'); // Debug log
      _lastErrorMessage = error.toString();
      throw Exception(_lastErrorMessage);
    }
  }
}

class Vendor {
  final String id;
  final String name;
  final String email;
  final String mobileNumber;
  final String? referenceCode;

  Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.mobileNumber,
    this.referenceCode,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      mobileNumber: json['mobileNumber'],
      referenceCode: json['referenceCode'],
    );
  }
}
