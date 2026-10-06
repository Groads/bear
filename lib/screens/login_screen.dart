
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Control para mostrar/ocultar la contraseña
  bool _obscure = true;

  // Cerebro de la animación
  StateMachineController? _controller;

  // SMI: State Machine Input / Entrada de máquina de estado
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  // Variable del recorrido de la mirada
  SMINumber? _numLook;

  // Timer
  Timer? _typingDebounce;

  // FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // Controllers que manipulan lo que escribe el usuario
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Errores para mostrar en la UI
  String? emailError;
  String? passError;

  // ============================================================
  // REMEMBER ME
  // ============================================================

  bool _rememberMe = false;
  bool _isRememberAnimating = false;

  late AnimationController _rememberMeAnimationController;

  bool get _canUseRememberMe {
    return _emailCtrl.text.trim().isNotEmpty &&
        _passCtrl.text.isNotEmpty;
  }

  void _toggleRememberMe() {
    // No permitir interacción mientras está animando
    if (!_canUseRememberMe || _isRememberAnimating) {
      return;
    }

    setState(() {
      _rememberMe = !_rememberMe;
      _isRememberAnimating = true;
    });

    _rememberMeAnimationController.forward(from: 0);
  }

  // ============================================================
  // VALIDADORES
  // ============================================================

  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );

    return re.hasMatch(pass);
  }

  // ============================================================
  // LOGIN
  // ============================================================

  void _onLogin() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    final eError = isValidEmail(email) ? null : 'Invalid email';
    final pError =
        isValidPassword(pass) ? null : 'Invalid password';

    setState(() {
      emailError = eError;
      passError = pError;
    });

    // Cancelar el timer de escritura
    _typingDebounce?.cancel();

    // ==========================================================
    // NUEVO COMPORTAMIENTO:
    //
    // Datos correctos -> oso feliz
    // Datos incorrectos -> oso triste/error
    //
    // No necesitamos presionar Login dos veces.
    // ==========================================================

    if (eError == null && pError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }

    // Quitar el teclado después de disparar la animación
    FocusScope.of(context).unfocus();
  }

  @override
  void initState() {
    super.initState();

    // ============================================================
    // REMEMBER ME - ANIMACIÓN
    // ============================================================

    _rememberMeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rememberMeAnimationController.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          if (!mounted) return;

          setState(() {
            _isRememberAnimating = false;
          });
        }
      },
    );

    // ============================================================
    // ANIMACIONES DEL OSO
    // ============================================================

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp?.change(false);
          _numLook?.value = 50.0;
        }
      }
    });

    _passwordFocus.addListener(() {
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();

    _rememberMeAnimationController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();

    _emailCtrl.dispose();
    _passCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ==================================================
              // OSO RIVE
              // ==================================================

              SizedBox(
                height: size.height * 0.30,
                child: RiveAnimation.asset(
                  'assets/login-bear.riv',
                  stateMachines: const ['Login Machine'],
                  onInit: (artboard) {
                    _controller = StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );

                    if (_controller == null) return;

                    artboard.addController(_controller!);

                    _isChecking =
                        _controller!.findSMI('isChecking');

                    _isHandsUp =
                        _controller!.findSMI('isHandsUp');

                    _trigSuccess =
                        _controller!.findSMI('trigSuccess');

                    _trigFail =
                        _controller!.findSMI('trigFail');

                    _numLook =
                        _controller!.findSMI('numLook');
                  },
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // EMAIL
              // ==================================================

              TextField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                onChanged: (value) {
                  // Actualizar Remember Me
                  setState(() {});

                  // Mantener animación original del oso
                  if (_isHandsUp != null) {
                    // _isHandsUp!.change(false);
                  }

                  if (_isChecking == null) return;

                  _isChecking!.change(true);

                  final look = (value.length / 50.0 * 100.0)
                      .clamp(0.0, 100.0);

                  _numLook?.value = look;

                  _typingDebounce?.cancel();

                  _typingDebounce = Timer(
                    const Duration(seconds: 3),
                    () {
                      if (!mounted) return;

                      _isChecking?.change(false);
                    },
                  );
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  errorText: emailError,
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // PASSWORD
              // ==================================================

              TextField(
                controller: _passCtrl,
                focusNode: _passwordFocus,
                onChanged: (value) {
                  // Actualizar Remember Me
                  setState(() {});

                  // Mantener animación original del oso
                  if (_isChecking != null) {
                    // _isChecking!.change(false);
                  }

                  if (_isHandsUp == null) return;

                  _isHandsUp!.change(true);
                },
                obscureText: _obscure,
                decoration: InputDecoration(
                  errorText: passError,
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // REMEMBER ME + FORGOT PASSWORD
              // ==================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: (!_canUseRememberMe ||
                            _isRememberAnimating)
                        ? null
                        : _toggleRememberMe,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation:
                              _rememberMeAnimationController,
                          builder: (context, child) {
                            final scale = 1.0 +
                                (_rememberMeAnimationController
                                        .value *
                                    0.10);

                            return Transform.scale(
                              scale: scale,
                              child: AnimatedContainer(
                                duration:
                                    const Duration(
                                  milliseconds: 200,
                                ),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: !_canUseRememberMe
                                      ? Colors.grey.shade200
                                      : _rememberMe
                                          ? Colors.deepPurple
                                          : Colors.transparent,
                                  border: Border.all(
                                    color: !_canUseRememberMe
                                        ? Colors.grey
                                        : Colors.deepPurple,
                                    width: 2,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(
                                    milliseconds: 150,
                                  ),
                                  child: _rememberMe
                                      ? const Icon(
                                          Icons.check,
                                          key: ValueKey(
                                            'checked',
                                          ),
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : const SizedBox(
                                          key: ValueKey(
                                            'unchecked',
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 14,
                            color: !_canUseRememberMe
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Text(
                    'Forgot password?',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ==================================================
              // LOGIN
              // ==================================================

              MaterialButton(
                onPressed: _onLogin,
                color: Colors.deepPurple,
                minWidth: size.width,
                height: 50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // REGISTER
              // ==================================================

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
