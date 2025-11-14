const jwt = require('jsonwebtoken');

class AuthService {
  static generateToken(userId) {
    return jwt.sign(
      { userId }, 
      process.env.JWT_SECRET, 
      { expiresIn: '30d' }
    );
  }

  static verifyToken(token) {
    return jwt.verify(token, process.env.JWT_SECRET);
  }
}

module.exports = AuthService;