import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    //Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child:Column(
            children: [
              SizedBox(
                height: size.width,
                child: RiveAnimation.asset('assets')
              ),
            ],
         ),
        ),
      ),
    );
  }
}