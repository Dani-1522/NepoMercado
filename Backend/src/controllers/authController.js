const User = require('../models/User');
const AuthService = require('../services/authService');
const { sendWhatsApp } = require('../services/notificationService');

const authController = {
  async register(req, res) {
    try {
      const { name, phone, password } = req.body;

      // Verificar si el usuario ya existe
      const existingUser = await User.findOne({ phone });
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Ya existe un usuario con este teléfono'
        });
      }

      // Crear nuevo usuario
      const user = new User({
        name,
        phone,
        passwordHash: password // Se encripta automáticamente en el pre-save
      });

      await user.save();

      // Generar token
      const token = AuthService.generateToken(user._id);

      res.status(201).json({
        success: true,
        message: 'Usuario registrado exitosamente',
        data: {
          user: {
            id: user._id,
            name: user.name,
            phone: user.phone
          },
          token
        }
      });

    } catch (error) {
      console.error('Error en registro:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  async login(req, res) {
    try {
      const { phone, password } = req.body;

      // Buscar usuario
      const user = await User.findOne({ phone });
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Teléfono o contraseña incorrectos'
        });
      }

      // Verificar contraseña
      const isPasswordValid = await user.comparePassword(password);
      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          message: 'Teléfono o contraseña incorrectos'
        });
      }

      // Generar token
      const token = AuthService.generateToken(user._id);

      res.json({
        success: true,
        message: 'Login exitoso',
        data: {
          user: {
            id: user._id,
            name: user.name,
            phone: user.phone
          },
          token
        }
      });

    } catch (error) {
      console.error('Error en login:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },
  
  async forgotPassword(req, res) {
  try {
    const { phone } = req.body;

    console.log('📞 Solicitando recuperación para:', phone);

    // Validar formato de teléfono
    if (!phone || phone.length < 10) {
      return res.status(400).json({
        success: false,
        message: 'Número de teléfono inválido. Debe tener al menos 10 dígitos.'
      });
    }

    const user = await User.findOne({ phone });
    if (!user) {
      // Por seguridad, no revelar que el usuario no existe
      console.log('📞 Usuario no encontrado para:', phone);
      return res.json({
        success: true, // ✅ Devuelve éxito aunque no exista por seguridad
        message: 'Si el número está registrado, recibirás un código por WhatsApp.'
      });
    }

    // Generar código de 6 dígitos
    const recoveryCode = Math.floor(100000 + Math.random() * 900000).toString();
    const recoveryCodeExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 minutos

    user.recoveryCode = recoveryCode;
    user.recoveryCodeExpires = recoveryCodeExpires;
    await user.save();

    console.log('🔐 Código generado para', phone, ':', recoveryCode);

    // Enviar código por WhatsApp
    const message = `🔐 Código de recuperación - Artesanos App\n\n` +
                   `Tu código de verificación es: *${recoveryCode}*\n\n` +
                   `Este código expira en 15 minutos.\n\n` +
                   `Si no solicitaste este código, ignora este mensaje.`;

    try {
      console.log('📤 Intentando enviar WhatsApp...');
      await sendWhatsApp(phone, message);
      console.log('✅ WhatsApp enviado exitosamente');

      res.json({
        success: true,
        message: 'Código de recuperación enviado por WhatsApp'
      });

    } catch (whatsappError) {
      console.error('❌ Error enviando WhatsApp:', whatsappError.message);
      
      // Si falla WhatsApp, limpiar el código
      user.recoveryCode = null;
      user.recoveryCodeExpires = null;
      await user.save();

      return res.status(500).json({
        success: false,
        message: 'Error enviando WhatsApp. Por favor intenta más tarde.'
      });
    }

  } catch (error) {
    console.error('❌ Error en forgotPassword:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
},

  // ✅ NUEVO: Verificar código
  async verifyRecoveryCode(req, res) {
    try {
      const { phone, code } = req.body;

      const user = await User.findOne({ 
        phone, 
        recoveryCode: code,
        recoveryCodeExpires: { $gt: new Date() }
      });

      if (!user) {
        return res.status(400).json({
          success: false,
          message: 'Código inválido o expirado'
        });
      }

      // Generar token temporal para reset
      const tempToken = AuthService.generateToken(user._id);

      res.json({
        success: true,
        message: 'Código verificado',
        data: { tempToken,
          userId: user._id
         }
      });

    } catch (error) {
      console.error('Error en verifyRecoveryCode:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  // ✅ NUEVO: Resetear contraseña
  async resetPassword(req, res) {
    try {
      const { tempToken, newPassword } = req.body;

      const decoded = AuthService.verifyToken(tempToken);
      const user = await User.findById(decoded.userId);

      if (!user) {
        return res.status(400).json({
          success: false,
          message: 'Token inválido'
        });
      }

      // Actualizar contraseña
      user.passwordHash = newPassword;
      user.recoveryCode = null;
      user.recoveryCodeExpires = null;
      await user.save();

      res.json({
        success: true,
        message: 'Contraseña actualizada exitosamente'
      });

    } catch (error) {
      console.error('Error en resetPassword:', error);
      res.status(500).json({
        success: false,
        message: 'Token inválido o expirado'
      });
    }
  }
};


module.exports = authController;