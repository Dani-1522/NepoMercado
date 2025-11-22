const Product = require('../models/Product');
const CloudinaryService = require('../services/cloudinaryService');

const productController = {
  async createProduct(req, res) {
  try {
  
    const { name, price, description, category } = req.body;
    // Validar campos requeridos
      if (!name || !price || !description || !category) {
        return res.status(400).json({
          success: false,
          message: 'Todos los campos son requeridos: nombre, precio, descripción'
        });
      }

      //  Validar múltiples archivos
      if (!req.files || req.files.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Al menos una imagen es requerida'
        });
      }

      // Subir múltiples imágenes a Cloudinary
      const uploadPromises = req.files.map(file => 
        CloudinaryService.uploadImage(file.buffer)
      );
      
      const uploadResults = await Promise.all(uploadPromises);
      const imageUrls = uploadResults.map(result => result.secure_url);

   

    
    const product = new Product({
      userId: req.user._id,
      name: name.trim(),
      price: parseFloat(price),
      description: description.trim(),
      category: category,
      imageUrls
    });

    await product.save();
          await product.populate('userId', 'name phone profileImage');


    res.status(201).json({
      success: true,
      message: 'Producto creado exitosamente',
      data: { product }
    });

  } catch (error) {
    console.error(' Error creando producto:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
}, 

  async updateProduct(req, res) {
    try {
      const { name, price, description, category } = req.body;
      const productId = req.params.id;

      const product = await Product.findById(productId);
      
      if (!product) {
        return res.status(404).json({
          success: false,
          message: 'Producto no encontrado'
        });
      }

      // Verificar que el usuario es el dueño del producto
      if (product.userId.toString() !== req.user._id.toString()) {
        return res.status(403).json({
          success: false,
          message: 'No tienes permiso para editar este producto'
        });
      }

      // Actualizar campos
      if (name) product.name = name.trim();
      if (price) product.price = parseFloat(price);
      if (description) product.description = description.trim();
      if (category) product.category = category;

      // Manejar nuevas imágenes si se enviaron
      if (req.files && req.files.length > 0) {
        console.log(' Actualizando imágenes del producto...');
        
        // Subir nuevas imágenes a Cloudinary
        const uploadPromises = req.files.map(file => 
          CloudinaryService.uploadImage(file.buffer)
        );
        
        const uploadResults = await Promise.all(uploadPromises);
        const newImageUrls = uploadResults.map(result => result.secure_url);
        
        // Reemplazar las imágenes existentes
        product.imageUrls = newImageUrls;
      }

      await product.save();
      await product.populate('userId', 'name phone profileImage');

      res.json({
        success: true,
        message: 'Producto actualizado exitosamente',
        data: { product }
      });

    } catch (error) {
      console.error('Error actualizando producto:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  //  NUEVO: Obtener productos por usuario con paginación
async getProductsByUser(req, res) {
  try {
    const userId = req.params.userId;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const products = await Product.find({ userId })
      .populate('userId', 'name phone profileImage')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Product.countDocuments({ userId });

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
    console.error('Error obteniendo productos del usuario:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
},
  // NUEVO: Eliminar producto
  async deleteProduct(req, res) {
    try {
      const productId = req.params.id;

      const product = await Product.findById(productId);
      
      if (!product) {
        return res.status(404).json({
          success: false,
          message: 'Producto no encontrado'
        });
      }

      // Verificar que el usuario es el dueño del producto
      if (product.userId.toString() !== req.user._id.toString()) {
        return res.status(403).json({
          success: false,
          message: 'No tienes permiso para eliminar este producto'
        });
      }

    

      await Product.findByIdAndDelete(productId);

      res.json({
        success: true,
        message: 'Producto eliminado exitosamente'
      });

    } catch (error) {
      console.error('Error eliminando producto:', error);
      res.status(500).json({
        success: false,
        message: 'Error interno del servidor'
      });
    }
  },

  // Búsqueda y filtros de productos
async searchProducts(req, res) {
  try {
    const {
      query,
      category,
      minPrice,
      maxPrice,
      sortBy = 'createdAt',
      sortOrder = 'desc',
      page = 1,
      limit = 10
    } = req.query;

    // Construir filtro
    const filter = {};

    // Filtro por texto (búsqueda)
    if (query && query.trim() !== '') {
      filter.$or = [
        { name: { $regex: query.trim(), $options: 'i' } },
        { description: { $regex: query.trim(), $options: 'i' } }
      ];
    }

    // Filtro por categoría (para futura implementación)
    if (category && category !== 'todos' && category !== 'all') {
      filter.category = category;
    }

    // Filtro por precio
    if (minPrice || maxPrice) {
      filter.price = {};
      if (minPrice) filter.price.$gte = parseFloat(minPrice);
      if (maxPrice) filter.price.$lte = parseFloat(maxPrice);
    }

    // Configurar ordenamiento
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === 'asc' ? 1 : -1;

    // Calcular paginación
    const skip = (parseInt(page) - 1) * parseInt(limit);

    console.log('Filtros de búsqueda:', filter);
    console.log('Opciones de ordenamiento:', sortOptions);

    // Ejecutar consulta
    const products = await Product.find(filter)
      .populate('userId', 'name phone profileImage')
      .sort(sortOptions)
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Product.countDocuments(filter);

    const categoryStats = await Product.aggregate([
      { $match: filter },
      { $group: { _id: '$category', count: { $sum: 1 } } }
    ]);


    // Obtener estadísticas para los filtros
    const priceStats = await Product.aggregate([
      { $match: filter },
      {
        $group: {
          _id: null,
          minPrice: { $min: '$price' },
          maxPrice: { $max: '$price' },
          avgPrice: { $avg: '$price' }
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        products,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        },
        filters: {
          priceRange: priceStats.length > 0 ? {
            min: priceStats[0].minPrice,
            max: priceStats[0].maxPrice,
            avg: priceStats[0].avgPrice
          } : { min: 0, max: 0, avg: 0 },
          categories: categoryStats
        }
      }
    });

  } catch (error) {
    console.error('Error en búsqueda de productos:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor'
    });
  }
},

  //  Endpoint para obtener todas las categorías disponibles
async getCategories(req, res) {
  try {
    const categories = [
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
    ];

    // Obtener conteo de productos por categoría
    const categoryCounts = await Product.aggregate([
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 }
        }
      }
    ]);

    // Combinar categorías con sus conteos
    const categoriesWithCounts = categories.map(cat => {
      const countData = categoryCounts.find(item => item._id === cat);
      return {
        name: cat,
        count: countData ? countData.count : 0
      };
    });

    res.json({
      success: true,
      data: {
        categories: categoriesWithCounts
      }
    });

  } catch (error) {
    console.error('Error obteniendo categorías:', error);
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
      const userId = req.user._id.toString();
      const hasLiked = product.likes.includes(userId);

      if (hasLiked) {
        product.likes.pull(userId);
        product.likeCount -= 1;
      } else {
        product.likes.push(userId);
        product.likeCount += 1;
      }
      await product.save();
      const newLikedState = !hasLiked;

      res.json({
        success: true,
        message: hasLiked ? 'Like removido' : 'Like agregado',
        data: {
          liked: newLikedState,
          likeCount: product.likeCount,
          
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
        .populate('userId', 'name phone profileImage')
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
        .populate('userId', 'name phone profileImage')
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
        .populate('userId', 'name phone profileImage');

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
        .populate('userId', 'name phone profileImage')
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