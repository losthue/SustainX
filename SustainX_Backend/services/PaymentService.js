const { sequelize } = require('../config/db');
const { QueryTypes } = require('sequelize');

// Coin packages
const COIN_PACKAGES = {
    '1': { name: 'Starter', coins: 100, bonus: 10,  price: 199 },
    '2': { name: 'Popular', coins: 500, bonus: 50,  price: 799 },
    '3': { name: 'Pro',     coins: 1000, bonus: 200, price: 1499 },
    '4': { name: 'Elite',   coins: 2500, bonus: 500, price: 3499 },
};

class PaymentService {

    static getStripe() {
        const key = process.env.STRIPE_SECRET_KEY;
        if (!key) throw new Error('STRIPE_SECRET_KEY not configured');
        return require('stripe')(key);
    }

    // ── Get available packages ───────────────────────────────────────────
    static getPackages() {
        return Object.entries(COIN_PACKAGES).map(([id, pkg]) => ({
            id,
            ...pkg,
            total_coins: pkg.coins + pkg.bonus,
            currency: 'MUR',
        }));
    }

    // ── Get or create Stripe customer ────────────────────────────────────
    static async _getOrCreateCustomer(userId) {
        const stripe = PaymentService.getStripe();

        // Check if user already has a Stripe customer ID stored
        const [rows] = await sequelize.query(
            'SELECT stripe_customer_id FROM users WHERE user_id = ?',
            { replacements: [userId] }
        );

        if (rows.length > 0 && rows[0].stripe_customer_id) {
            return rows[0].stripe_customer_id;
        }

        // Create new Stripe customer
        const customer = await stripe.customers.create({
            metadata: { sustainx_user_id: userId },
        });

        // Try to store it (column may not exist yet)
        try {
            await sequelize.query(
                'UPDATE users SET stripe_customer_id = ? WHERE user_id = ?',
                { replacements: [customer.id, userId] }
            );
        } catch (e) {
            // Column doesn't exist yet — that's okay, we'll still use the customer
            console.warn('Could not save stripe_customer_id:', e.message);
        }

        return customer.id;
    }

    // ── Create Payment Intent for mobile payment sheet ───────────────────
    static async createPaymentIntent(userId, packageId) {
        const pkg = COIN_PACKAGES[packageId];
        if (!pkg) throw new Error('Invalid package ID');

        const stripe = PaymentService.getStripe();

        // Get or create customer
        const customerId = await PaymentService._getOrCreateCustomer(userId);

        // Create ephemeral key for the customer
        const ephemeralKey = await stripe.ephemeralKeys.create(
            { customer: customerId },
            { apiVersion: '2024-12-18.acacia' }
        );

        // Create payment intent
        const paymentIntent = await stripe.paymentIntents.create({
            amount: pkg.price * 100, // cents
            currency: 'mur',
            customer: customerId,
            metadata: {
                user_id: userId,
                package_id: packageId,
                coin_amount: String(pkg.coins),
                bonus_amount: String(pkg.bonus),
                total_coins: String(pkg.coins + pkg.bonus),
            },
        });

        // Record pending purchase
        await sequelize.query(
            `INSERT INTO purchases (user_id, package_id, package_name, coin_amount, bonus_amount, total_coins, price_cents, currency, stripe_payment_id, status)
             VALUES (:userId, :pkgId, :name, :coins, :bonus, :total, :price, 'MUR', :paymentId, 'pending')`,
            {
                replacements: {
                    userId,
                    pkgId: packageId,
                    name: pkg.name,
                    coins: pkg.coins,
                    bonus: pkg.bonus,
                    total: pkg.coins + pkg.bonus,
                    price: pkg.price * 100,
                    paymentId: paymentIntent.id,
                },
            }
        );

        return {
            payment_intent: paymentIntent.client_secret,
            ephemeral_key: ephemeralKey.secret,
            customer_id: customerId,
            publishable_key: process.env.STRIPE_PUBLISHABLE_KEY || '',
        };
    }

    // ── Confirm payment and credit coins ─────────────────────────────────
    static async confirmPayment(paymentIntentId) {
        const stripe = PaymentService.getStripe();

        const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

        if (paymentIntent.status !== 'succeeded') {
            return { success: false, message: `Payment status: ${paymentIntent.status}` };
        }

        const userId = paymentIntent.metadata.user_id;
        const totalCoins = parseInt(paymentIntent.metadata.total_coins) || 0;

        // Check if already fulfilled
        const [existing] = await sequelize.query(
            'SELECT * FROM purchases WHERE stripe_payment_id = ? AND status = ?',
            { replacements: [paymentIntentId, 'completed'] }
        );

        if (existing && existing.length > 0) {
            return { success: true, message: 'Already fulfilled', already_fulfilled: true };
        }

        // Credit green coins
        await sequelize.query(
            `UPDATE wallets 
             SET green_coins = green_coins + :coins, updated_at = CURRENT_TIMESTAMP
             WHERE user_id = :userId`,
            { replacements: { coins: totalCoins, userId } }
        );

        // Auto-offset red coins with green coins if no yellow coins available
        const WalletService = require('./WalletService');
        const offsetAmount = await WalletService.autoOffsetGreenReceiver(userId);

        // Update purchase status
        await sequelize.query(
            `UPDATE purchases 
             SET status = 'completed', completed_at = CURRENT_TIMESTAMP
             WHERE stripe_payment_id = :paymentId`,
            { replacements: { paymentId: paymentIntentId } }
        );

        // Log transaction
        await sequelize.query(
            `INSERT INTO transactions (sender_id, receiver_id, coin_type, amount, transaction_type, note, status)
             VALUES (NULL, :userId, 'green', :coins, 'purchase', :note, 'completed')`,
            {
                replacements: {
                    userId,
                    coins: totalCoins,
                    note: `Purchased ${paymentIntent.metadata.coin_amount} + ${paymentIntent.metadata.bonus_amount} bonus green coins`,
                },
            }
        );

        return { 
            success: true, 
            coins_credited: totalCoins, 
            red_coins_offset: offsetAmount,
            user_id: userId 
        };
    }

    // ── Purchase history ─────────────────────────────────────────────────
    static async getPurchaseHistory(userId) {
        const [rows] = await sequelize.query(
            'SELECT * FROM purchases WHERE user_id = ? ORDER BY created_at DESC LIMIT 20',
            { replacements: [userId] }
        );
        return rows;
    }
}

module.exports = PaymentService;
