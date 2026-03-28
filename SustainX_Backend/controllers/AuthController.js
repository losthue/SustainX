const AuthService = require('../services/AuthService');

class AuthController {
    // Register
    static async register(req, res, next) {
        try {
            const { user_id, user_type, name, email, password } = req.body;

            if (!user_id || !user_type || !email || !password) {
                return res.status(400).json({
                    success: false,
                    message: 'user_id, user_type, email, and password are required',
                });
            }

            if (!['prosumer', 'consumer'].includes(user_type)) {
                return res.status(400).json({
                    success: false,
                    message: 'user_type must be "prosumer" or "consumer"',
                });
            }

            const result = await AuthService.register(user_id, user_type, name, email, password);
            return res.status(201).json(result);
        } catch (err) {
            next(err);
        }
    }

    // Login
    static async login(req, res, next) {
        try {
            const { user_id, password } = req.body;

            if (!user_id || !password) {
                return res.status(400).json({
                    success: false,
                    message: 'user_id and password are required',
                });
            }

            const result = await AuthService.login(user_id, password);
            return res.status(200).json(result);
        } catch (err) {
            if (err.message === 'Invalid user ID or password') {
                return res.status(401).json({ success: false, message: err.message });
            }
            next(err);
        }
    }

    // Get profile
    static async getProfile(req, res, next) {
        try {
            const profile = await AuthService.getUserProfile(req.userId);
            return res.status(200).json({ success: true, data: profile });
        } catch (err) {
            next(err);
        }
    }

    // Update profile
    static async updateProfile(req, res, next) {
        try {
            const { name } = req.body;
            const updatedProfile = await AuthService.updateProfile(req.userId, name);
            return res.status(200).json({
                success: true,
                message: 'Profile updated successfully',
                data: updatedProfile,
            });
        } catch (err) {
            next(err);
        }
    }
}

module.exports = AuthController;
