const express = require('express');
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');
const uploadProfileMiddleware = require('../middleware/uploadProfileMiddleware');

const router = express.Router();

//ruta publica
router.get('/:id', userController.getUserProfile);

//ruta Protegida
router.get('/profile/me', authMiddleware, userController.getMyProfile);
router.put('/profile/update', authMiddleware, userController.updateProfile);
router.put('/profile/change-password', authMiddleware, userController.changePassword);
router.put('/profile/upload-image', authMiddleware, uploadProfileMiddleware, userController.updateProfileImage);
router.delete('/profile/delete-image', authMiddleware, userController.deleteProfileImage);

module.exports = router;