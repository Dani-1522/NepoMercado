// middleware/uploadProfileMiddleware.js
const multer = require('multer');

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
 

  const getMimeTypeFromExtension = (filename) => {
    const ext = filename.toLowerCase().split('.').pop();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp'
    };
    return mimeTypes[ext] || file.mimetype;
  };

  const actualMimeType = getMimeTypeFromExtension(file.originalname);
  const allowedMimes = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/webp',
    'image/gif'
  ];

  if (allowedMimes.includes(actualMimeType)) {
    file.mimetype = actualMimeType;
    cb(null, true);
  } else {
    cb(new Error(`Tipo de archivo no permitido. Solo se permiten imágenes: ${allowedMimes.join(', ')}`), false);
  }
};

const uploadProfile = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 2 * 1024 * 1024, // 2MB máximo para foto de perfil
    files: 1 // Solo 1 archivo
  }
}).single('profileImage'); // Campo 'profileImage'

module.exports = uploadProfile;