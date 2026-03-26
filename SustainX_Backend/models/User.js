const { DataTypes, Model } = require('sequelize');
const bcrypt = require('bcryptjs');
const { sequelize } = require('../config/db');

class User extends Model {
    async comparePassword(candidatePassword) {
        return bcrypt.compare(candidatePassword, this.password);
    }

    getTotalBalance() {
        return this.yellowCoins + this.greenCoins + this.redCoins;
    }

    getWalletInfo() {
        return {
            userId: this.id,
            username: this.username,
            walletAddress: this.walletAddress,
            balances: {
                yellowCoins: this.yellowCoins,
                greenCoins: this.greenCoins,
                redCoins: this.redCoins,
            },
            totalBalance: this.getTotalBalance(),
            energyScore: this.energyScore,
        };
    }
}

User.init(
    {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
            allowNull: false,
        },
        username: {
            type: DataTypes.STRING,
            allowNull: false,
            unique: true,
            validate: { len: [3, 50] },
        },
        email: {
            type: DataTypes.STRING,
            allowNull: false,
            unique: true,
            validate: { isEmail: true },
        },
        password: {
            type: DataTypes.STRING,
            allowNull: false,
            validate: { len: [6, 100] },
        },
        yellowCoins: { type: DataTypes.DECIMAL(16, 2), defaultValue: 0 },
        greenCoins: { type: DataTypes.DECIMAL(16, 2), defaultValue: 0 },
        redCoins: { type: DataTypes.DECIMAL(16, 2), defaultValue: 0 },
        energyScore: { type: DataTypes.INTEGER, defaultValue: 0 },
        walletAddress: { type: DataTypes.STRING, unique: true },
        fullName: { type: DataTypes.STRING },
        profileImage: { type: DataTypes.STRING },
        deviceTokens: { type: DataTypes.JSON },
    },
    {
        sequelize,
        modelName: 'User',
        tableName: 'users',
        timestamps: true,
        hooks: {
            beforeCreate: async (user) => {
                if (user.password) {
                    user.password = await bcrypt.hash(user.password, 10);
                }
                if (!user.walletAddress) {
                    user.walletAddress = `wallet_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
                }
            },
            beforeUpdate: async (user) => {
                if (user.changed('password')) {
                    user.password = await bcrypt.hash(user.password, 10);
                }
            },
        },
    }
);

module.exports = User;
