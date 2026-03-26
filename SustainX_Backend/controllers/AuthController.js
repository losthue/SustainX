const AuthService = require('../services/AuthService');

class AuthController {
    // Register controller
    static async register(req, res, next) {
        try {
            const { username, email, password, fullName } = req.body;

            // Validate input
            if (!username || !email || !password) {
                return res.status(400).json({
                    success: false,
                    message: 'Username, email, and password are required'
                });
            }

            // Register user
            const result = await AuthService.register(username, email, password, fullName);

            return res.status(201).json(result);
        } catch (err) {
            next(err);
        }
    }

    // Login controller
    static async login(req, res, next) {
        try {
            const { email, password } = req.body;

            // Validate input
            if (!email || !password) {
                return res.status(400).json({
                    success: false,
                    message: 'Email and password are required'
                });
            }

            // Login user
            const result = await AuthService.login(email, password);

            return res.status(200).json(result);
        } catch (err) {
            if (err.message === 'Invalid email or password') {
                return res.status(401).json({
                    success: false,
                    message: err.message
                });
            }
            next(err);
        }
    }

    // Get profile controller
    static async getProfile(req, res, next) {
        try {
            const userId = req.userId;

            const profile = await AuthService.getUserProfile(userId);

            return res.status(200).json({
                success: true,
                data: profile
            });
        } catch (err) {
            next(err);
        }
    }

    // Update profile controller
    static async updateProfile(req, res, next) {
        try {
            const userId = req.userId;
            const { fullName, profileImage } = req.body;

            const updatedProfile = await AuthService.updateProfile(userId, fullName, profileImage);

            return res.status(200).json({
                success: true,
                message: 'Profile updated successfully',
                data: updatedProfile
            });
        } catch (err) {
            next(err);
        }
    }
}

module.exports = AuthController;
