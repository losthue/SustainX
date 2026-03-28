const { DataTypes, Model } = require('sequelize');
const bcrypt = require('bcryptjs');
const { sequelize } = require('../config/db');

class User extends Model {
    async comparePassword(candidatePassword) {
        return bcrypt.compare(candidatePassword, this.password_hash);
    }
}

User.init(
    {
        user_id: {
            type: DataTypes.STRING(10),
            primaryKey: true,
            allowNull: false,
        },
        user_type: {
            type: DataTypes.ENUM('prosumer', 'consumer'),
            allowNull: false,
        },
        name: {
            type: DataTypes.STRING(100),
            allowNull: true,
        },
        email: {
            type: DataTypes.STRING(150),
            allowNull: false,
            unique: true,
            validate: { isEmail: true },
        },
        password_hash: {
            type: DataTypes.STRING(255),
            allowNull: false,
        },
        is_active: {
            type: DataTypes.BOOLEAN,
            defaultValue: true,
        },
    },
    {
        sequelize,
        modelName: 'User',
        tableName: 'users',
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at',
        hooks: {
            beforeCreate: async (user) => {
                if (user.password_hash && !user.password_hash.startsWith('$2')) {
                    user.password_hash = await bcrypt.hash(user.password_hash, 10);
                }
            },
            beforeUpdate: async (user) => {
                if (user.changed('password_hash') && !user.password_hash.startsWith('$2')) {
                    user.password_hash = await bcrypt.hash(user.password_hash, 10);
                }
            },
        },
    }
);

module.exports = User;
