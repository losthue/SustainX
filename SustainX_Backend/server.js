const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Import middleware and routes
const errorHandler = require('./middleware/errorHandler');
const authRoutes = require('./routes/authRoutes');
const walletRoutes = require('./routes/walletRoutes');
const energyRoutes = require('./routes/energyRoutes');
const transactionRoutes = require('./routes/transactionRoutes');

// Import Sequelize connection
const { testConnection, sequelize } = require('./config/db');

// Initialize Express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Connect to MySQL and sync models
const connectDB = async () => {
    try {
        await testConnection();
        await sequelize.sync({ alter: true });
        console.log('✓ MySQL models synchronized');
    } catch (err) {
        console.error('✗ MySQL sync failed:', err.message);
        process.exit(1);
    }
};

connectDB();

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        message: 'EnergyPass Backend is running',
        timestamp: new Date().toISOString(),
        database: 'MySQL',
        databaseStatus: 'connected',
    });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/energy', energyRoutes);
app.use('/api/transactions', transactionRoutes);

// Welcome endpoint
app.get('/', (req, res) => {
    res.status(200).json({
        message: 'Welcome to EnergyPass Backend API',
        version: '1.0.0',
        endpoints: {
            auth: '/api/auth',
            wallet: '/api/wallet',
            energy: '/api/energy',
            transactions: '/api/transactions'
        }
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found',
        path: req.originalUrl
    });
});

// Error handling middleware (must be last)
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 5000;

const server = app.listen(PORT, () => {
    console.log(`
    ╔════════════════════════════════════════╗
    ║    EnergyPass Backend Server Started   ║
    ╠════════════════════════════════════════╣
    ║  Port: ${PORT}
    ║  Environment: ${process.env.NODE_ENV || 'development'}
    ║  Database: MySQL
    ╚════════════════════════════════════════╝
    `);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
    console.error('Unhandled Rejection:', err);
    server.close(() => process.exit(1));
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('SIGTERM received. Shutting down gracefully...');
    server.close(async () => {
        console.log('Server closed');
        try {
            await sequelize.close();
            console.log('MySQL connection closed');
        } catch (err) {
            console.error('Error closing MySQL connection:', err);
        }
        process.exit(0);
    });
});

module.exports = app;
