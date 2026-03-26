// Database configuration
module.exports = {
    db: {
        host: process.env.DB_HOST || '127.0.0.1',
        port: process.env.DB_PORT || 3306,
        database: process.env.DB_NAME || 'energypass',
        username: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || ''
    },
    jwt: {
        secret: process.env.JWT_SECRET || 'your_super_secret_jwt_key_change_this_in_production',
        expiresIn: process.env.JWT_EXPIRATION || '7d'
    },
    cors: {
        origin: (process.env.CORS_ORIGIN || 'http://localhost:3000').split(','),
        credentials: true,
        optionsSuccessStatus: 200
    },
    server: {
        port: process.env.PORT || 5000,
        environment: process.env.NODE_ENV || 'development'
    },
    energy: {
        defaultConversionRate: process.env.DEFAULT_CONVERSION_RATE || 10
    }
};
