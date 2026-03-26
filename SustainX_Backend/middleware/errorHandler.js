// Error handling middleware
const errorHandler = (err, req, res, next) => {
    console.error('Error:', err.message);

    if (err.name === 'ValidationError') {
        return res.status(400).json({
            success: false,
            message: 'Validation error',
            errors: Object.values(err.errors).map(e => e.message)
        });
    }

    if (err.name === 'MongoError' || err.name === 'MongoServerError') {
        return res.status(400).json({
            success: false,
            message: 'Database error',
            details: err.message
        });
    }

    if (err.name === 'CastError') {
        return res.status(400).json({
            success: false,
            message: 'Invalid ID format',
            details: err.message
        });
    }

    return res.status(err.statusCode || 500).json({
        success: false,
        message: err.message || 'Internal server error',
        details: process.env.NODE_ENV === 'development' ? err.stack : undefined
    });
};

module.exports = errorHandler;
