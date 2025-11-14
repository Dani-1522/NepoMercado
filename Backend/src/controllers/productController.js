const Product = require('../models/Product');
const CloudinaryService = require('../services/cloudinaryService');

const productController = {
  async createProduct(req, res) {
  try {
  
    const { name, price, description } = req.body;
    // Validar campos requeridos
      if (!name || !price || !description) {
        return res.status(400).json({
          success: false,
          message: 'Todos los campos son requeridos: nombre, precio, descripción'
        });
      }

      // ✅ CAMBIADO: Validar múltiples archivos
      if (!req.files || req.files.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Al menos una imagen es requerida'
        });
      }

      // ✅ NUEVO: Subir múltiples imágenes a Cloudinary
      console.log('☁️ Subiendo', req.files.length, 'imágenes a Cloudinary...');
      const uploadPromises = req.files.map(file => 
        CloudinaryService.uploadImage(file.buffer)
      );
      
      const uploadResults = await Promise.all(uploadPromises);
      const imageUrls = uploadResults.map(result => result.secure_url);

      console.log('✅ Imágenes subidas:', imageUrls);

    
    const product = new Product({
      userId: req.user._id,
      name: name.trim(),
      price: parseFloat(price),
      description: description.trim(),
      imageUrls
    });

    await product.save();
    await product.populate('userId', 'name phone');

    res.status(201).json({
      success: true,
      message: 'Producto creado exitosamente',
      data: { product }
    });

  } catch (error) {
    console.error('❌ Error creando producto:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
}, 

  async toggleLike(req, res) {
    try {
      const product = await Product.findById(req.params.id);

      if (!product) {
        return res.status(404).json({
          success: false,
          message: 'Producto no encontrado'
        });
      }
      const userId = req.user._id;
      const hasLiked = product.likes.includes(userId);

      if (hasLiked) {
        product.likes.pull(userId);
        product.likeCount -= 1;
      } else {
        product.likes.push(userId);
        product.likeCount += 1;
      }
      await product.save();

      res.json({
        success: true,
        message: hasLiked ? 'Like removido' : 'Like agregado',
        data: {
          likeCount: product.likeCount,
          likes: product.likes
        }
      });
    } catch (error) {
      console.error('Error toggling like:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  
  async getLikedProducts(req, res) {
    try {
      const products = await Product.find({ 
        likes: req.user._id })
        .populate('userId', 'name phone')
        .sort({ createdAt: -1 });

      res.json({
        success: true,
        data: { products }
      });
    } catch (error) {
      console.error('Error obteniendo productos liked:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  async getAllProducts(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const skip = (page - 1) * limit;

      const products = await Product.find()
        .populate('userId', 'name phone')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit);

      const total = await Product.countDocuments();

      res.json({
        success: true,
        data: {
          products,
          pagination: {
            page,
            limit,
            total,
            pages: Math.ceil(total / limit)
          }
        }
      });

    } catch (error) {
      console.error('Error obteniendo productos:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  async getProductById(req, res) {
    try {
      const product = await Product.findById(req.params.id)
        .populate('userId', 'name phone');

      if (!product) {
        return res.status(404).json({
          success: false,
          message: 'Producto no encontrado'
        });
      }

      res.json({
        success: true,
        data: { product }
      });

    } catch (error) {
      console.error('Error obteniendo producto:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  async getUserProducts(req, res) {
    try {
      const products = await Product.find({ userId: req.user._id })
        .sort({ createdAt: -1 });

      res.json({
        success: true,
        data: { products }
      });

    } catch (error) {
      console.error('Error obteniendo productos del usuario:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  }
};

module.exports = productController;