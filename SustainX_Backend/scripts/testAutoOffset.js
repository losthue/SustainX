const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { sequelize, testConnection } = require('../config/db');
const EnergyService = require('../services/EnergyService');
const WalletService = require('../services/WalletService');

(async () => {
  try {
    await testConnection();
    await sequelize.sync({ alter: true });

    const testUserId = 'PR001'; // Assuming this user exists

    console.log('Testing auto-offset functionality...');

    // First, check current wallet balance
    const walletBefore = await WalletService.getWallet(testUserId);
    console.log('Wallet before:', {
      yellow: walletBefore.yellow_coins,
      green: walletBefore.green_coins,
      red: walletBefore.red_coins
    });

    // Record energy with surplus (should generate yellow coins and auto-offset red debt)
    console.log('Recording energy surplus (10 kWh export, 5 kWh import)...');
    const result = await EnergyService.recordReading(testUserId, 5, 15, 999); // net +10 kWh

    console.log('Record result:', result);
    console.log('Coins generated:', result.reading.coins_generated);

    // Check wallet after
    const walletAfter = await WalletService.getWallet(testUserId);
    console.log('Wallet after:', {
      yellow: walletAfter.yellow_coins,
      green: walletAfter.green_coins,
      red: walletAfter.red_coins
    });

    console.log('Test completed successfully!');

  } catch (error) {
    console.error('Test failed:', error);
  } finally {
    await sequelize.close();
  }
})();