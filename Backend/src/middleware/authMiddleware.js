 const jwt = require('jsonwebtoken');
const User = require('../models/User');

const authMiddleware = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ 
        success: false, 
        message: 'Token de acceso requerido' 
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId).select('-passwordHash');
    
    if (!user) {
      return res.status(401).json({ 
        success: false, 
        message: 'Token inválido - usuario no encontrado' 
      });
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('Error en auth middleware:', error);
    res.status(401).json({ 
      success: false, 
      message: 'Token inválido' 
    });
  }
};

module.exports = authMiddleware;