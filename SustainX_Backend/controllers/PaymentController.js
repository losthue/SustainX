const PaymentService = require('../services/PaymentService');

class PaymentController {

    // GET /payments/packages
    static async getPackages(req, res, next) {
        try {
            const packages = PaymentService.getPackages();
            return res.status(200).json({ success: true, data: packages });
        } catch (err) { next(err); }
    }

    // POST /payments/create-payment-intent
    // Body: { package_id: string }
    static async createPaymentIntent(req, res, next) {
        try {
            const { package_id } = req.body;
            if (!package_id) {
                return res.status(400).json({ success: false, message: 'package_id is required' });
            }

            const result = await PaymentService.createPaymentIntent(req.userId, package_id);
            return res.status(200).json({ success: true, data: result });
        } catch (err) {
            if (err.message?.includes('Invalid package')) {
                return res.status(400).json({ success: false, message: err.message });
            }
            console.error('Payment intent error:', err);
            next(err);
        }
    }

    // POST /payments/confirm
    // Body: { payment_intent_id: string }
    static async confirmPayment(req, res, next) {
        try {
            const { payment_intent_id } = req.body;
            if (!payment_intent_id) {
                return res.status(400).json({ success: false, message: 'payment_intent_id required' });
            }

            const result = await PaymentService.confirmPayment(payment_intent_id);
            return res.status(200).json({ success: true, data: result });
        } catch (err) { next(err); }
    }

    // GET /payments/history
    static async getPurchaseHistory(req, res, next) {
        try {
            const history = await PaymentService.getPurchaseHistory(req.userId);
            return res.status(200).json({ success: true, data: history });
        } catch (err) { next(err); }
    }
}

module.exports = PaymentController;
