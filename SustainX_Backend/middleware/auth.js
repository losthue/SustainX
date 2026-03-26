const jwt = require('jsonwebtoken');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'your_secret_key_here';

// Middleware to verify JWT token
const authMiddleware = async (req, res, next) => {
    try {
        // Get token from header
        const token = req.header('Authorization')?.replace('Bearer ', '');

        if (!token) {
            return res.status(401).json({ 
                success: false,
                message: 'No authentication token. Access denied.' 
            });
        }

        // Verify token
        const decoded = jwt.verify(token, JWT_SECRET);
        
        // Find user by primary key (Sequelize uses findByPk)
        const user = await User.findByPk(decoded.userId);
        
        if (!user) {
            return res.status(401).json({ 
                success: false,
                message: 'User not found. Invalid token.' 
            });
        }

        // Attach user to request
        req.user = user;
        req.userId = decoded.userId;
        
        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({ 
                success: false,
                message: 'Token expired. Please login again.' 
            });
        }
        
        return res.status(401).json({ 
            success: false,
            message: 'Invalid token. Access denied.' 
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

// Optional: Admin middleware (can be extended later)
const adminMiddleware = async (req, res, next) => {
    try {
        // Check if user is admin (add admin field to User model if needed)
        if (req.user && req.user.role === 'admin') {
            next();
        } else {
            return res.status(403).json({ 
                success: false,
                message: 'Admin access required.' 
            });
        }
    } catch (err) {
        res.status(500).json({ 
            success: false,
            message: 'Error checking admin status.' 
        });
    }
};

module.exports = {
    authMiddleware,
    generateToken,
    adminMiddleware,
    JWT_SECRET
};
