const { Op } = require('sequelize');
const User = require('../models/User');
const { generateToken } = require('../middleware/auth');

class AuthService {
    static async register(username, email, password, fullName = '') {
        const existingUser = await User.findOne({
            where: {
                [Op.or]: [{ username }, { email }],
            },
        });

        if (existingUser) {
            throw new Error('Username or email already exists');
        }

        const user = await User.create({
            username,
            email,
            password,
            fullName: fullName || username,
        });

        const token = generateToken(user.id);

        return {
            success: true,
            message: 'User registered successfully',
            user: {
                id: user.id,
                username: user.username,
                email: user.email,
                walletAddress: user.walletAddress,
            },
            token,
        };
    }

    static async login(email, password) {
        const user = await User.findOne({ where: { email } });

        if (!user) {
            throw new Error('Invalid email or password');
        }

        const isPasswordValid = await user.comparePassword(password);
        if (!isPasswordValid) {
            throw new Error('Invalid email or password');
        }

        const token = generateToken(user.id);

        return {
            success: true,
            message: 'Login successful',
            user: {
                id: user.id,
                username: user.username,
                email: user.email,
                walletAddress: user.walletAddress,
            },
            token,
        };
    }

    static async getUserProfile(userId) {
        const user = await User.findByPk(userId);
        if (!user) throw new Error('User not found');
        return user.getWalletInfo();
    }

    static async updateProfile(userId, fullName, profileImage) {
        const user = await User.findByPk(userId);
        if (!user) throw new Error('User not found');

        user.fullName = fullName || user.fullName;
        user.profileImage = profileImage || user.profileImage;
        await user.save();

        return user.getWalletInfo();
    }
}

module.exports = AuthService;
