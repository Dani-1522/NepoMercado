import 'package:flutter/material.dart';
import 'package:NepoMercado/screens/auth/reset_password_screen.dart';
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
          backgroundColor: const Color(0xFFE9965C), 
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verificar Código',
          style: TextStyle(
            color: Color(0xFF202124), 
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFFF4EDE4), 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Color(0xFF0F4C5C)), 
        foregroundColor: const Color(0xFF0F4C5C), 
      ),
      body: Container(
        color: const Color(0xFFF4EDE4), 
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono y título
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F4C5C).withOpacity(0.1), 
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user,
                            size: 50,
                            color: Color(0xFF0F4C5C), 
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Verificar Código',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F4C5C), 
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Texto descriptivo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3A9188).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.phone_iphone,
                              color: const Color(0xFF3A9188), 
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Código enviado por WhatsApp',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F4C5C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa el código de 6 dígitos que recibiste en el número:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B), 
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.phone,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F4C5C), 
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo de código
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Código de verificación',
                      labelStyle: const TextStyle(color: Color(0xFF64748B)),
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF3A9188)),
                      hintText: '123456',
                      counterText: '', 
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFF3A9188).withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0F4C5C), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
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
                  
                  // Contador personalizado
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_codeController.text.length}/6 dígitos',
                      style: TextStyle(
                        fontSize: 12,
                        color: _codeController.text.length == 6 
                            ? const Color(0xFF3A9188) 
                            : const Color(0xFF64748B), 
                        fontWeight: _codeController.text.length == 6 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Botón de verificar
                  if (_isLoading)
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF0F4C5C), 
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Verificando código...',
                            style: TextStyle(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C5C), 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Verificar Código',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                  // Información adicional
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9965C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9965C).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: const Color(0xFFE9965C), 
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Código con tiempo limitado',
                                style: TextStyle(
                                  color: const Color(0xFF0F4C5C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'El código expirará en 10 minutos por seguridad',
                                style: TextStyle(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botón de reenviar código
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Código reenviado exitosamente'),
                            backgroundColor: const Color(0xFF3A9188), 
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      child: Text(
                        '¿No recibiste el código? Reenviar',
                        style: TextStyle(
                          color: const Color(0xFF0F4C5C),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}