const User = require('../models/User');
const CloudinaryService = require('../services/cloudinaryService');
const bcrypt = require('bcryptjs');

const userController = {
  async getUserProfile(req, res) {
    try {
      const user = await User.findById(req.params.id)
        .select('-passwordHash -recoveryCode -recoveryCodeExpires');

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'Usuario no encontrado'
        });
      }

      res.json({
        success: true,
        data: { user }
      });

    } catch (error) {
      console.error('Error obteniendo perfil:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  async getMyProfile(req, res) {
    try {
      const user = await User.findById(req.user._id)
        .select('-passwordHash -recoveryCode -recoveryCodeExpires');

      res.json({
        success: true,
        data: {user}
      });

    } catch (error) {
      console.error('Error obteniendo perfil propio:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  async updateProfile(req, res) {
    try {
      const { name, phone } = req.body;
      const userId = req.user._id;

      if(phone){
        const existingUser = await User.findOne({ phone, _id: { $ne: userId } });
        if (existingUser) {
          return res.status(400).json({
            success: false,
            message: 'El teléfono ya está en uso por otro usuario'
          });
        }
      }
      const updateData = {};
      if (name) updateData.name = name.trim();
      if (phone) updateData.phone = phone;

      const user = await User.findByIdAndUpdate(
        userId,
        updateData,
        { new: true, runValidators: true }
      ).select('-passwordHash -recoveryCode -recoveryCodeExpires');

      res.json({
        success: true,
        message: 'Perfil actualizado exitosamente',
        data: { user }
      });

    } catch (error) {
      console.error('Error actualizando perfil:', error);
      
      if (error.name === 'ValidationError') {
        return res.status(400).json({
          success: false,
          message: Object.values(error.errors).map(err => err.message).join(', ')
        });
      }

      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  // 🔥 NUEVO: Cambiar contraseña
  async changePassword(req, res) {
    try {
      const { currentPassword, newPassword } = req.body;
      const userId = req.user._id;

      if (!currentPassword || !newPassword) {
        return res.status(400).json({
          success: false,
          message: 'La contraseña actual y nueva son requeridas'
        });
      }

      if (newPassword.length < 6) {
        return res.status(400).json({
          success: false,
          message: 'La nueva contraseña debe tener al menos 6 caracteres'
        });
      }

      const user = await User.findById(userId);
      
      // Verificar contraseña actual
      const isCurrentPasswordValid = await user.comparePassword(currentPassword);
      if (!isCurrentPasswordValid) {
        return res.status(400).json({
          success: false,
          message: 'La contraseña actual es incorrecta'
        });
      }

      // Actualizar contraseña
      user.passwordHash = newPassword;
      await user.save();

      res.json({
        success: true,
        message: 'Contraseña actualizada exitosamente'
      });

    } catch (error) {
      console.error('Error cambiando contraseña:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  // 🔥 NUEVO: Subir/actualizar foto de perfil
  async updateProfileImage(req, res) {
    try {
      const userId = req.user._id;
      
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No se ha proporcionado ninguna imagen'
        });
      }

      const user = await User.findById(userId);
      
      // Si ya tiene una foto de perfil, eliminar la anterior de Cloudinary
      if (user.profileImage) {
        try {
          const publicId = user.profileImage.split('/').pop().split('.')[0];
          await CloudinaryService.deleteImage(`artesanos/${publicId}`);
        } catch (deleteError) {
          console.warn('⚠️ No se pudo eliminar la imagen anterior:', deleteError.message);
        }
      }

      // Subir nueva imagen a Cloudinary
      const uploadResult = await CloudinaryService.uploadImage(req.file.buffer);
      
      // Actualizar usuario con nueva imagen
      user.profileImage = uploadResult.secure_url;
      await user.save();

      const userResponse = user.toObject();
      delete userResponse.passwordHash;
      delete userResponse.recoveryCode;
      delete userResponse.recoveryCodeExpires;

      res.json({
        success: true,
        message: 'Foto de perfil actualizada exitosamente',
        data: { user: userResponse }
      });

    } catch (error) {
      console.error('Error actualizando foto de perfil:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  // 🔥 NUEVO: Eliminar foto de perfil
  async deleteProfileImage(req, res) {
    try {
      const userId = req.user._id;
      const user = await User.findById(userId);

      if (!user.profileImage) {
        return res.status(400).json({
          success: false,
          message: 'No tienes una foto de perfil para eliminar'
        });
      }

      // Eliminar imagen de Cloudinary
      try {
        const publicId = user.profileImage.split('/').pop().split('.')[0];
        await CloudinaryService.deleteImage(`artesanos/${publicId}`);
      } catch (deleteError) {
        console.warn('⚠️ No se pudo eliminar la imagen de Cloudinary:', deleteError.message);
      }

      // Eliminar referencia en la base de datos
      user.profileImage = null;
      await user.save();

      const userResponse = user.toObject();
      delete userResponse.passwordHash;
      delete userResponse.recoveryCode;
      delete userResponse.recoveryCodeExpires;

      res.json({
        success: true,
        message: 'Foto de perfil eliminada exitosamente',
        data: { user: userResponse }
      });

    } catch (error) {
      console.error('Error eliminando foto de perfil:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }
};

module.exports = userController;
