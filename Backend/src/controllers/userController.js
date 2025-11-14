const User = require('../models/User');

const userController = {
  async getUserProfile(req, res) {
    try {
      const user = await User.findById(req.params.id)
        .select('-passwordHash');

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
      res.json({
        success: true,
        data: { user: req.user }
      });

    } catch (error) {
      console.error('Error obteniendo perfil propio:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }
};

module.exports = userController;