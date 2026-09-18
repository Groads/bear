import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
//Control para mostrar/ocultar la contraseña
  bool _obscure = true;

  //1.1 Crear el cerebro de la animacion
  StateMachineController? _controller;
  //SMI: State Machine Input / Entrada de maquina de estado
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;


  @override
  Widget build(BuildContext context) {
    //Para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'login-bear.riv',
                  stateMachines: ['Login Machine'],
                  //1.2 Vincular animacion
                  onInit:(artboard){
                    _controller = StateMachineController.fromArtboard(artboard,'Login Machine',);

                    //1.3 verificar que inicio bien
                    if(_controller == null) return;
                    artboard.addController(_controller!);
                    //vinculamos variables
                    _isChecking = _controller!.findSMI('isChecking');
                    _isHandsUp = _controller!.findSMI('isHandsUp');
                    _trigSuccess = _controller!.findSMI('trigSuccess');
                    _trigFail = _controller!.findSMI('trigFail');

                  },
                ),
              ),
              //Para separar espacios
              SizedBox(height: 10),
              //Email
              TextField(
                onChanged:(value){
                  if(_isHandsUp != null){
                  //no tapes los ojos al ver email
                  _isHandsUp!.change(false);
                  }
                
                //Si isCheking e snulo
                if (_isChecking == null) return;
                //Activar el modo chismoso
                _isChecking!.change(true);
                },
                //Para mostrar el tipo de teclado
                keyboardType: TextInputType.emailAddress,
                decoration:InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    //Para redondear los bordes
                    borderRadius: BorderRadius.circular(12)
                  )
                ),
              ),

              SizedBox(height: 10),
              //Para Contraseña
              TextField(
                onChanged:(value){
                  if(_isChecking !=null){
                  //no tapes los ojos al ver email
                  _isChecking!.change(false);
                  }
                
                //Si isCheking e snulo
                if (_isHandsUp== null) return;
                //Activar el modo chismoso
                _isHandsUp!.change(true);
                },
                //Para mostrar el tipo de teclado
                obscureText: _obscure,
                decoration:InputDecoration(
                  hintText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon:IconButton(
                    icon:Icon(
                     _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed:(){
                      //Refrescar el icono
                      setState(() {
                        _obscure = !_obscure;
                      });
                    }
                  ),
                  border: OutlineInputBorder(
                    //Para redondear los bordes
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}