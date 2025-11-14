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
      
      if (!phone || phone.length < 10) {
        return res.status(400).json({
          success: false,
          message: 'Número de teléfono inválido'
        });
      }

      const user = await User.findOne({ phone });
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'No existe usuario con este número'
        });
      }

      // Generar código de 6 dígitos
      const recoveryCode = Math.floor(100000 + Math.random() * 900000).toString();
      const recoveryCodeExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 minutos

      user.recoveryCode = recoveryCode;
      user.recoveryCodeExpires = recoveryCodeExpires;
      await user.save();

      // Enviar código por SMS o WhatsApp
      const message = `Tu código de recuperación es: ${recoveryCode}. Válido por 15 minutos.`;
      
     const simpleMessage = `Codigo de recuperacio de NepoMercado - Tu código de recuperación es: ${recoveryCode}. Válido por 15 minutos.`;
      await sendWhatsApp(phone, simpleMessage);

      res.json({
        success: true,
        message: 'Código de recuperación enviado'
      });

    } catch (error) {
      console.error('Error en forgotPassword:', error);
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