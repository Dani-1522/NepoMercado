const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'El nombre es obligatorio'],
    trim: true,
    maxlength: [50, 'El nombre no puede tener más de 50 caracteres']
  },
  phone: {
    type: String,
    required: [true, 'El teléfono es obligatorio'],
    unique: true,
    match: [/^\+?[\d\s\-\(\)]+$/, 'Formato de teléfono inválido']
  },
  passwordHash: {
    type: String,
    required: [true, 'La contraseña es obligatoria'],
    minlength: [6, 'La contraseña debe tener al menos 6 caracteres']
  },
  recoveryCode:{
    type: String,
    default: null
  },
  recoveryCodeExpiration:{
    type: Date,
    default: null
  }
}, {
  timestamps: true
});

// Método para comparar contraseñas
userSchema.methods.comparePassword = async function(password) {
  return await bcrypt.compare(password, this.passwordHash);
};

// Middleware para encriptar contraseña antes de guardar
userSchema.pre('save', async function(next) {
  if (!this.isModified('passwordHash')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.passwordHash = await bcrypt.hash(this.passwordHash, salt);
    next();
  } catch (error) {
    next(error);
  }
});

module.exports = mongoose.model('User', userSchema);