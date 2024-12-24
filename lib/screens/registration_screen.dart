import 'package:flutter/material.dart';

class RegistrationScreen extends StatelessWidget {
  static const routeName = '/register';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Center(child: Text('Registration Screen')),
    );
  }
}
