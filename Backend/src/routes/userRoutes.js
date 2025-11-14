const express = require('express');
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/:id', userController.getUserProfile);
router.get('/profile/me', authMiddleware, userController.getMyProfile);

module.exports = router;