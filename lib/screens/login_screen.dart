import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'products_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSubscription;

  User? _currentUser;
  bool _showAuthenticated = false;
  bool _isLoggingIn = false;
  // Reproduce directamente las animaciones success/fail del archivo .riv.
  String? _riveReaction;
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
  String? authError;

  // ============================================================
  // REMEMBER ME
  // ============================================================

  bool _rememberMe = false;
  bool _isRememberAnimating = false;

  late AnimationController _rememberMeAnimationController;

  bool get _canUseRememberMe {
    return _emailCtrl.text.trim().isNotEmpty && _passCtrl.text.isNotEmpty;
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

  Future<void> _showRiveReaction(String animation) async {
    if (!mounted) return;
    _typingDebounce?.cancel();
    FocusScope.of(context).unfocus();
    _isChecking?.change(false);
    _isHandsUp?.change(false);

    // La máquina de estados controla la interacción al escribir.
    // Para los resultados reproducimos directamente el clip de Rive,
    // sin depender de las transiciones internas de Login Machine.
    setState(() => _riveReaction = animation);
    _isChecking = null;
    _isHandsUp = null;
    _numLook = null;
    _trigSuccess = null;
    _trigFail = null;
    _controller = null;
    debugPrint('RIVE: reproduciendo animación $animation');

    await Future.delayed(
      Duration(milliseconds: animation == 'success' ? 2100 : 1700),
    );

    if (mounted && animation == 'fail') {
      setState(() => _riveReaction = null);
    }
  }

  Future<void> _onLogin() async {
    if (_isLoggingIn) return;

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final eError = isValidEmail(email) ? null : 'Introduce un correo válido';
    final pError = isValidPassword(password)
        ? null
        : 'Mínimo 8 caracteres, mayúscula, minúscula, número y símbolo';

    setState(() {
      emailError = eError;
      passError = pError;
      authError = null;
      _isLoggingIn = true;
    });

    try {
      if (eError != null || pError != null) {
        await _showRiveReaction('fail');
        return;
      }

      // No activar isChecking durante el envío: pertenece a la
      // animación de escritura, no a la autenticación.
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;

      // Firebase emitirá authStateChanges, pero _isLoggingIn impide
      // navegar hasta haber mostrado la reacción.
      _currentUser = credential.user;

      await _showRiveReaction('success');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'El correo electrónico no es válido.';
          break;
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'Correo o contraseña incorrectos.';
          break;
        case 'user-disabled':
          message = 'Esta cuenta está deshabilitada.';
          break;
        case 'network-request-failed':
          message = 'Comprueba tu conexión a Internet.';
          break;
        case 'too-many-requests':
          message = 'Demasiados intentos. Intenta más tarde.';
          break;
        default:
          message = 'No se pudo iniciar sesión.';
      }
      setState(() => authError = message);
      await _showRiveReaction('fail');
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error de autenticación: $e');
      setState(() => authError = 'Ocurrió un error inesperado.');
      await _showRiveReaction('fail');
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_isLoggingIn) return;

    try {
      // Cerrar sesión en Firebase.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // Detener animaciones y temporizadores.
      _typingDebounce?.cancel();

      // El artboard del login puede estar desmontado en esta pantalla.
      _isChecking = null;
      _isHandsUp = null;
      _numLook = null;
      _trigSuccess = null;
      _trigFail = null;
      _controller = null;

      _rememberMeAnimationController.reset();

      // Quitar el foco de los campos.
      _emailFocus.unfocus();
      _passwordFocus.unfocus();

      // Limpiar los datos locales.
      _emailCtrl.clear();
      _passCtrl.clear();

      setState(() {
        _currentUser = null;
        _showAuthenticated = false;
        _riveReaction = null;

        _rememberMe = false;
        _isRememberAnimating = false;
        _obscure = true;

        emailError = null;
        passError = null;
      });

      // Limpiar mensajes anteriores.
      ScaffoldMessenger.of(context).clearSnackBars();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      debugPrint('Error al cerrar sesión: ${e.code}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar la sesión. Inténtalo de nuevo.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('Error inesperado al cerrar sesión: $e');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al cerrar sesión.')));
    }
  }

  @override
  void initState() {
    super.initState();
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (!mounted) return;

      setState(() {
        _currentUser = user;

        if (user == null) {
          _showAuthenticated = false;
        } else if (!_isLoggingIn) {
          _showAuthenticated = true;
        }
      });
    });

    // ============================================================
    // REMEMBER ME - ANIMACIÓN
    // ============================================================

    _rememberMeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _rememberMeAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;

        setState(() {
          _isRememberAnimating = false;
        });
      }
    });

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
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showAuthenticated && _currentUser != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Inicio'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),

        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),

              const SizedBox(height: 20),

              const Text(
                '¡Inicio de sesión exitoso!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Text(_currentUser!.email ?? 'Usuario autenticado'),

              const SizedBox(height: 32),

              // BOTÓN PARA CERRAR SESIÓN
              ElevatedButton.icon(
                onPressed: _signOut,

                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                child: _riveReaction != null
                    ? RiveAnimation.asset(
                        'assets/login-bear.riv',
                        key: ValueKey('reaction-$_riveReaction'),
                        animations: [_riveReaction!],
                        fit: BoxFit.contain,
                      )
                    : RiveAnimation.asset(
                        'assets/login-bear.riv',
                        key: const ValueKey('login-machine'),
                        onInit: (artboard) {
                          _controller = StateMachineController.fromArtboard(
                            artboard,
                            'Login Machine',
                          );
                          if (_controller == null) return;
                          artboard.addController(_controller!);
                          _isChecking = _controller!.findSMI('isChecking');
                          _isHandsUp = _controller!.findSMI('isHandsUp');
                          _trigSuccess = _controller!.findSMI('trigSuccess');
                          _trigFail = _controller!.findSMI('trigFail');
                          _numLook = _controller!.findSMI('numLook');
                        },
                      ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
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

                  final look = (value.length / 50.0 * 100.0).clamp(0.0, 100.0);

                  _numLook?.value = look;

                  _typingDebounce?.cancel();

                  _typingDebounce = Timer(const Duration(seconds: 3), () {
                    if (!mounted) return;

                    _isChecking?.change(false);
                  });
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
              const SizedBox(height: 24),
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
                      _obscure ? Icons.visibility : Icons.visibility_off,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: (!_canUseRememberMe || _isRememberAnimating)
                        ? null
                        : _toggleRememberMe,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _rememberMeAnimationController,
                          builder: (context, child) {
                            final scale =
                                1.0 +
                                (_rememberMeAnimationController.value * 0.10);

                            return Transform.scale(
                              scale: scale,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
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
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  child: _rememberMe
                                      ? const Icon(
                                          Icons.check,
                                          key: ValueKey('checked'),
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : const SizedBox(
                                          key: ValueKey('unchecked'),
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

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              if (authError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    authError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 24),

              // ==================================================
              // LOGIN
              // ==================================================
              MaterialButton(
                onPressed: _isLoggingIn ? null : _onLogin,
                color: Colors.deepPurple,
                minWidth: size.width,
                height: 50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoggingIn
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // REGISTER
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
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
