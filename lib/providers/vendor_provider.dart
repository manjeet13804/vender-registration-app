import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VendorProvider with ChangeNotifier {
  String _token = '';
  List<Vendor> _vendors = [];

  List<Vendor> get vendors => _vendors;

  Future<void> login(String username, String password) async {
    final url = Uri.parse('http://localhost:5000/api/auth/login');
    final response = await http.post(url,
      body: json.encode({
        'username': username,
        'password': password,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      _token = responseData['token'];
      notifyListeners();
    } else {
      throw Exception('Failed to log in');
    }
  }

  Future<void> sendOtp(String mobileNumber) async {
    final url = Uri.parse('http://localhost:5000/api/auth/send-otp');
    final response = await http.post(
      url,
      body: json.encode({
        'mobileNumber': mobileNumber,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP');
    }
  }

  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    final url = Uri.parse('http://localhost:5000/api/auth/verify-otp');
    final response = await http.post(
      url,
      body: json.encode({
        'mobileNumber': mobileNumber,
        'otp': otp,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Invalid OTP');
    }
  }

  Future<void> registerVendor(String name, String email, String password, String mobileNumber, {String? referenceCode}) async {
    final url = Uri.parse('http://localhost:5000/api/vendors');
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'mobileNumber': mobileNumber,
    };

    if (referenceCode != null && referenceCode.isNotEmpty) {
      body['referenceCode'] = referenceCode;
    }

    final response = await http.post(
      url,
      body: json.encode(body),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      _token = responseData['token'];
      notifyListeners();
    } else {
      throw Exception('Failed to register vendor');
    }
  }

  Future<void> fetchVendors() async {
    final url = Uri.parse('http://localhost:5000/api/vendors');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $_token'});

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body) as List;
      _vendors = responseData.map((vendor) => Vendor.fromJson(vendor)).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to fetch vendors');
    }
  }
}

class Vendor {
  final String name;
  final String email;
  final String mobileNumber;

  Vendor({required this.name, required this.email, required this.mobileNumber});

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      name: json['name'],
      email: json['email'],
      mobileNumber: json['mobileNumber'],
    );
  }
}
