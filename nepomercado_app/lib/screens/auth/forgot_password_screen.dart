import 'package:flutter/material.dart';
import 'package:NepoMercado/screens/auth/verify_code_screen.dart';
import '../../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendRecoveryCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final apiService = ApiService();
    final response = await apiService.forgotPassword(_phoneController.text.trim());

    setState(() => _isLoading = false);

    if (response.success) {

  // Navegar a la pantalla de verificación
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VerifyCodeScreen(phone: _phoneController.text.trim()),
    ),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(response.message),
      backgroundColor: Color(0xFFE9965C), 
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
          'Recuperar Contraseña',
          style: TextStyle(
            color: Color(0xFF202124), 
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFFF4EDE4), 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Color(0xFF0F4C5C)), 
        foregroundColor: Color(0xFF0F4C5C), 
      ),
      body: Container(
  color: Color(0xFFF4EDE4), 
  child: SafeArea(
    child: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(24.0), 
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFFE9965C).withOpacity(0.1), 
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 40,
                      color: Color(0xFFE9965C), 
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recuperar Contraseña',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F4C5C), 
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
              Text(
                    'Ingresa tu número de teléfono registrado para recibir un código de recuperación por WhatsApp',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B), 
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Número de teléfono',
                  labelStyle: TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: Icon(Icons.phone, color: Color(0xFF3A9188)),
                  hintText: '+573011234567',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF3A9188).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF0F4C5C), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu número de teléfono';
                  }
                  if (value.length < 10) {
                    return 'El número debe tener al menos 10 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
             if (_isLoading)
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF0F4C5C), 
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Enviando código...',
                          style: TextStyle(
                            color: Color(0xFF64748B),
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
                      onPressed: _sendRecoveryCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE9965C), 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Enviar Código por WhatsApp',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF3A9188).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF3A9188).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF3A9188),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Recibirás un código de 6 dígitos por WhatsApp para restablecer tu contraseña',
                          style: TextStyle(
                            color: Color(0xFF0F4C5C),
                            fontSize: 14,
                          ),  
                        ),
                      ),
                    ],  
                  ),
                ),
              ],
            ),  
          ),    
        ),
      ),
      ),
      )
    );
  }
}
                            