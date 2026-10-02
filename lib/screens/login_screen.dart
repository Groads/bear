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

 //4.1 Controllers que manipule lo que el usuario escribe
 final _emailCtrl = TextEditingController();
 final _passCtrl = TextEditingController();

 //4.2Erorres para mostralo en la UI
 String? emailError;
 String? passError;

 //4.3 validadores
 bool isValidEmail(String email){
  final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  return re.hasMatch(email);
 }

 bool isValidPassword(String pass){
  final re = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',);
  return re.hasMatch(pass);
 }

 //4.4 Dar accion al boton
 void _onLogin(){
  // 4.5 de lo que escribio el usuario,quitar espacios en blanco
  final email = _emailCtrl.text.trim();
  final pass = _passCtrl.text;

  //4.6 Evaluar errores
  final eError = isValidEmail(email) ? null : 'Invalid email';
  final pError = isValidPassword(pass) ? null : 'Invalid password';


  //4.7 Avisar que hubo cambios
  setState((){
    emailError = eError;
    passError = pError;
  });

  //4.8 Cerrar el teclado y bajar las manos
  FocusScope.of(context).unfocus(); //quita el foco
  _typingDebounce?.cancel(); //3.8 cancelar el timer
  _isChecking?.change(false);
  _isHandsUp?.change(false);
  _numLook?.value = 50.0; //mirada neutra

  //4.9 Activar triggers
  if (eError == null && pError == null){
     _trigSuccess?.fire();
  } else{
      _trigFail?.fire();
  }
 }

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
                //4.10 Enlazar controller
                controller: _emailCtrl,
                //2.3 
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
                  //4.11 mostrar error en la UI
                  errorText: emailError,
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
                //4.10 enlazar controller
                controller: _passCtrl,
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
                  errorText: passError,
                  hintText: 'Password',
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
             const SizedBox(height: 10),
              //4.12 Texto olvide la contraseña
              SizedBox(
                width: size.width,
                child: const Text(
                  'Forgot password?',
                  //alinear a la derecha
                  textAlign: TextAlign.right,
                  style: TextStyle(decoration: TextDecoration.underline)
                  ),
                ),
             const SizedBox(height: 10),
             //4.13 Boton de login
             MaterialButton(
              onPressed: _onLogin,
              minWidth: size.width,
              height: 50,
              color: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
                child: Text ('Login',
                style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: size.width,
                child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children:[
                    const Text("Don't have an account?"),
                    TextButton(onPressed: (){},
                    child: Text('Register',
                    style:TextStyle(decoration: TextDecoration.underline,
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                    ),
                    ),
                   )
                  ]
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
    //4.15 liberar los controladores
    _emailCtrl.dispose();
    _passCtrl.dispose();
    //2.4 Liberar espacio en memoria
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebounce?.cancel();//3.9 ELIMINAR EL TIMER 
    super.dispose();
  }
}