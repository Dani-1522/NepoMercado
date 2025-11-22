const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'El ID del usuario es obligatorio']
  },
  name: {
    type: String,
    required: [true, 'El nombre del producto es obligatorio'],
    trim: true,
    maxlength: [100, 'El nombre no puede tener más de 100 caracteres']
  },
  price: {
    type: Number,
    required: [true, 'El precio es obligatorio'],
    min: [0, 'El precio no puede ser negativo']
  },
  description: {
    type: String,
    required: [true, 'La descripción es obligatoria'],
    maxlength: [500, 'La descripción no puede tener más de 500 caracteres']
  },
  imageUrls: [{
    type: String,
    required: [true, 'Al menos una imagen es obligatoria']
  }],
  category: {
    type: String,
    required: [true, 'La categoría es obligatoria'],
    enum: [
      'comida',
      'ropa', 
      'artesanias',
      'electronica',
      'hogar',
      'deportes',
      'libros',
      'joyeria',
      'salud',
      'belleza',
      'juguetes',
      'mascotas',
      'otros'
    ],
    default: 'otros'
  },
  likes:[{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  likeCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Índice para búsquedas más eficientes
productSchema.index({ userId: 1, createdAt: -1 });
productSchema.index({ likes: 1 });
productSchema.index({ category: 1 });

module.exports = mongoose.model('Product', productSchema);