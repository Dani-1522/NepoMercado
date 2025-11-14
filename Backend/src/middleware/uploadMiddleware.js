const multer = require('multer');

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  console.log('🔍 MIDDLEWARE - Archivo recibido:');
  console.log('   - Original Name:', file.originalname);
  console.log('   - MIME Type:', file.mimetype);
  console.log('   - Size:', file.size, 'bytes');
  console.log('   - Field Name:', file.fieldname);

  // Detectar el tipo real por extensión
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
  console.log('   - MIME Type detectado por extensión:', actualMimeType);

  const allowedMimes = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/webp',
    'image/gif'
  ];

  // Usar el MIME type detectado por extensión
  if (allowedMimes.includes(actualMimeType)) {
    console.log('Archivo aceptado (MIME type corregido)');
    // Sobrescribir el MIME type incorrecto
    file.mimetype = actualMimeType;
    cb(null, true);
  } else {
    console.log('Archivo rechazado - No es imagen válida');
    cb(new Error(`Tipo de archivo no permitido: ${file.mimetype}. Solo se permiten imágenes: ${allowedMimes.join(', ')}`), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
    files: 5 // Máximo 5 archivos
  }
}).array('images', 5); // Espera un campo 'images' con hasta 5 archivos

module.exports = upload;