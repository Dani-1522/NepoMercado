const cloudinary = require('../config/cloudinary');
const stream = require('stream');

class CloudinaryService {
  static async uploadImage(buffer) {
    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: 'artesanos',
          transformation: [
            { width: 800, height: 600, crop: 'limit' },
            { quality: 'auto' },
            { format: 'webp' }
          ]
        },
        (error, result) => {
          if (error) reject(error);
          else resolve(result);
        }
      );

      // Crear stream desde buffer
      const bufferStream = new stream.PassThrough();
      bufferStream.end(buffer);
      bufferStream.pipe(uploadStream);
    });
  }

  static async deleteImage(publicId) {
    return await cloudinary.uploader.destroy(publicId);
  }
}

module.exports = CloudinaryService;  