import 'package:finance_tracker/pages/auth/login_page.dart';
import 'package:finance_tracker/pages/auth/signup_page.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  void togglePage() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLogin) {
      return LoginScreen(onClickSignUp: togglePage);
    } else {
      return SignUpScreen(onClickLogin: togglePage);
    }
  }
}
