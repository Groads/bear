
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  bool _requestCompleted = false;

  Future<void> _resetPassword() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.setLanguageCode('es');

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _requestCompleted = true;
      });

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'El correo electrónico no es válido.';
          break;

        case 'network-request-failed':
          message = 'Comprueba tu conexión a Internet.';
          break;

        case 'too-many-requests':
          message =
              'Demasiadas solicitudes. Intenta más tarde.';
          break;

        case 'user-not-found':
          // Evitar revelar si existe una cuenta.
          setState(() {
            _requestCompleted = true;
          });
          return;

        default:
          message =
              'No se pudo procesar la solicitud.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } catch (e) {
      if (!mounted) return;

      debugPrint('Error al recuperar contraseña: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error inesperado.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),

              child: _requestCompleted
                  ? _buildSuccess()
                  : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset,
            size: 85,
            color: Colors.deepPurple,
          ),

          const SizedBox(height: 20),

          const Text(
            '¿Olvidaste tu contraseña?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Introduce tu correo electrónico '
            'para recibir las instrucciones '
            'de recuperación de contraseña.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          TextFormField(
            controller: _emailCtrl,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [
              AutofillHints.email,
            ],
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'ejemplo@correo.com',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            validator: (value) {
              final email = value?.trim() ?? '';

              if (email.isEmpty) {
                return 'Introduce tu correo electrónico';
              }

              final regex = RegExp(
                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
              );

              if (!regex.hasMatch(email)) {
                return 'Introduce un correo válido';
              }

              return null;
            },
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _resetPassword,

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),

              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Enviar enlace de recuperación',
                    ),
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.pop(context),
            child: const Text('Volver al inicio de sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const Icon(
          Icons.mark_email_read,
          size: 90,
          color: Colors.green,
        ),

        const SizedBox(height: 24),

        const Text(
          '¡Solicitud procesada!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Si existe una cuenta asociada a ese correo, '
          'recibirás un enlace para restablecer '
          'tu contraseña.\n\n'
          'Revisa también tu carpeta de spam.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Volver al Login'),
          ),
        ),
      ],
    );
  }
}
