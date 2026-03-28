const { Op } = require('sequelize');
const User = require('../models/User');
const Wallet = require('../models/Wallet');
const { generateToken } = require('../middleware/auth');

class AuthService {
    static async register(user_id, user_type, name, email, password) {
        // Check for existing user
        const existingUser = await User.findOne({
            where: {
                [Op.or]: [{ user_id }, { email }],
            },
        });

        if (existingUser) {
            throw new Error('User ID or email already exists');
        }

        // Create user
        const user = await User.create({
            user_id,
            user_type,
            name: name || user_id,
            email,
            password_hash: password,
        });

        // Create wallet for user
        await Wallet.create({ user_id });

        const token = generateToken(user.user_id);

        return {
            success: true,
            message: 'User registered successfully',
            user: {
                user_id: user.user_id,
                user_type: user.user_type,
                name: user.name,
                email: user.email,
            },
            token,
        };
    }

    static async login(user_id, password) {
        const user = await User.findByPk(user_id);

        if (!user) {
            throw new Error('Invalid user ID or password');
        }

        if (!user.is_active) {
            throw new Error('Account is deactivated');
        }

        const isPasswordValid = await user.comparePassword(password);
        if (!isPasswordValid) {
            throw new Error('Invalid user ID or password');
        }

        const token = generateToken(user.user_id);

        return {
            success: true,
            message: 'Login successful',
            user: {
                user_id: user.user_id,
                user_type: user.user_type,
                name: user.name,
                email: user.email,
            },
            token,
        };
    }

    static async getUserProfile(userId) {
        const user = await User.findByPk(userId);
        if (!user) throw new Error('User not found');

        const wallet = await Wallet.findOne({ where: { user_id: userId } });

        return {
            user_id: user.user_id,
            user_type: user.user_type,
            name: user.name,
            email: user.email,
            is_active: user.is_active,
            wallet: wallet
                ? {
                      yellow_coins: parseFloat(wallet.yellow_coins),
                      green_coins: parseFloat(wallet.green_coins),
                      red_coins: parseFloat(wallet.red_coins),
                  }
                : null,
        };
    }

    static async updateProfile(userId, name) {
        const user = await User.findByPk(userId);
        if (!user) throw new Error('User not found');

        user.name = name || user.name;
        await user.save();

        return AuthService.getUserProfile(userId);
    }
}

module.exports = AuthService;
