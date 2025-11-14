import 'package:flutter/material.dart';
import 'package:nepomercado_app/screens/auth/reset_password_screen.dart';
import '../../services/api_service.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String phone;

  const VerifyCodeScreen({Key? key, required this.phone}) : super(key: key);

  @override
  _VerifyCodeScreenState createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final apiService = ApiService();
    final response = await apiService.verifyRecoveryCode(
      widget.phone,
      _codeController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      // Navegar a la pantalla de nueva contraseña
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(
            tempToken: response.data!['tempToken'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Código'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresa el código de 6 dígitos que recibiste en WhatsApp al número ${widget.phone}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Código de verificación',
                  prefixIcon: Icon(Icons.lock),
                  hintText: '123456',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el código';
                  }
                  if (value.length != 6) {
                    return 'El código debe tener 6 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _verifyCode,
                    child: const Text('Verificar Código'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}