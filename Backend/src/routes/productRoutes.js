const express = require('express');
const productController = require('../controllers/productController');
const authMiddleware = require('../middleware/authMiddleware');
const uploadMiddleware = require('../middleware/uploadMiddleware');

const router = express.Router();


// Middleware personalizado para manejar errores de multer
const handleUploadErrors = (err, req, res, next) => {
  if (err ) {
    return res.status(400).json({
      success: false,
      message: err.message
    });
  }
  next();
};

// Rutas públicas
router.get('/', productController.getAllProducts);
router.get('/:id', productController.getProductById);

// Ruta protegida para crear producto
router.post(
  '/', 
  authMiddleware, 
  uploadMiddleware, 
  handleUploadErrors,
  productController.createProduct
);

router.put(
  '/:id',
  authMiddleware,
  uploadMiddleware,
  handleUploadErrors,
  productController.updateProduct
);

router.delete(
  '/:id',
  authMiddleware,
  productController.deleteProduct
);

router.post(
  '/:id/like', 
  authMiddleware, 
  productController.toggleLike
);


router.get(
  '/search/all', 
  productController.searchProducts
);

router.get(
  '/user/liked',
  authMiddleware,
  productController.getLikedProducts
);

router.get(
  '/user/my-products', 
  authMiddleware, 
  productController.getUserProducts
);

module.exports = router;