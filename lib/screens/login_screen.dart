import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';//3.1 importar el timer

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

  //3.2 Variable del recorrido de la mirada
  SMINumber? _numLook;

  //3.3 Timer
  Timer? _typingDebounce;

  //2.1 Crear las variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();


  //2.2 Listeners (Oyentes/chismosos)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener((){
      if (_emailFocus.hasFocus){
      //Verificar que nosea nulo
      if(_isHandsUp != null){
        //Manos abajo en el email
        _isHandsUp?.change(false);
        //3.4 Mirada neutra
        _numLook?.value = 50.0;
       }
      }
    });

    _passwordFocus.addListener((){
      //Manos arriba en el password
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }


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
                  'assets/login-bear.riv',
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
                     //3.5 vincular numLook
                    _numLook = _controller!.findSMI('numLook');
                  },
                ),
              ),
              //Para separar espacios
              SizedBox(height: 10),
              //Email
              TextField(
                focusNode:_emailFocus,
                onChanged:(value){
                  if(_isHandsUp != null){
                  //no tapes los ojos al ver email
                  //_isHandsUp!.change(false);
                  }
                
                //Si isCheking e snulo
                if (_isChecking == null) return;
                //Activar el modo chismoso
                _isChecking!.change(true);

                //3.6 implementar numlook
                //Ajuste de limites del 0 al 100
                //50 es la medida de calibracion 
                final look = (value.length / 50.0 * 100.0) .clamp(0.0,100.0);
                //clamp es el rango (abrazadera)
                _numLook?.value = look;

                //3.7 Debouce: si vuleve a teclar,reinicia el numlook
                //cancelar cualquier timer existente
                _typingDebounce?.cancel();
                //Crear un nuevo timer
                _typingDebounce = Timer(const Duration(seconds: 3), () {
                  //si se cierra la pantalla,quita el contador
                  if (!mounted) return;
                  //mirada neutra
                  _isChecking?.change(false);
                });
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
                focusNode:_passwordFocus,
                onChanged:(value){
                  if(_isChecking !=null){
                  //no tapes los ojos al ver email
                  //_isChecking!.change(false);
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
  @override
  void dispose() {
    //2.4 Liberar espacio en memoria
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebounce?.cancel();//3.9 ELIMINAR EL TIMER 
    super.dispose();
  }
}