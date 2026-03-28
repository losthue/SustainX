const jwt = require('jsonwebtoken');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'your_secret_key_here';

// Middleware to verify JWT token
const authMiddleware = async (req, res, next) => {
    try {
        const token = req.header('Authorization')?.replace('Bearer ', '');

        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'No authentication token. Access denied.',
            });
        }

        const decoded = jwt.verify(token, JWT_SECRET);

        // Find user by user_id primary key
        const user = await User.findByPk(decoded.userId);

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'User not found. Invalid token.',
            });
        }

        if (!user.is_active) {
            return res.status(401).json({
                success: false,
                message: 'Account is deactivated.',
            });
        }

        req.user = user;
        req.userId = user.user_id;

        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                message: 'Token expired. Please login again.',
            });
        }

        return res.status(401).json({
            success: false,
            message: 'Invalid token. Access denied.',
        });
    }
};

// Generate JWT token
const generateToken = (userId) => {
    return jwt.sign(
        { userId },
        JWT_SECRET,
        { expiresIn: '7d' }
    );
};

module.exports = {
    authMiddleware,
    generateToken,
    JWT_SECRET,
};
