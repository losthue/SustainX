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

    console.log('Testing auto-offset when red coins are generated...');

    // First, give the user some yellow coins
    await sequelize.query(
      'UPDATE wallets SET yellow_coins = 10, red_coins = 0 WHERE user_id = ?',
      { replacements: [testUserId] }
    );
    console.log('Set user PR001 to have 10 yellow coins and 0 red coins');

    // Check wallet before
    const walletBefore = await WalletService.getWallet(testUserId);
    console.log('Wallet before energy recording:', {
      yellow: walletBefore.yellow_coins,
      green: walletBefore.green_coins,
      red: walletBefore.red_coins
    });

    // Record energy with deficit (should NOT generate coins immediately now)
    console.log('Recording energy deficit (20 kWh import, 5 kWh export)...');
    const recordResult = await EnergyService.recordReading(testUserId, 20, 5, 999); // net -15 kWh
    console.log('Record result coins_generated:', recordResult.reading.coins_generated);

    // Now generate coins for the cycle (this will generate red coins and auto-offset)
    console.log('Generating coins for cycle 999...');
    const genResult = await EnergyService.generateCoinsForCycle(999);
    console.log('Generate result:', genResult);

    // Check wallet after
    const walletAfter = await WalletService.getWallet(testUserId);
    console.log('Wallet after generateCoinsForCycle:', {
      yellow: walletAfter.yellow_coins,
      green: walletAfter.green_coins,
      red: walletAfter.red_coins
    });

    const redGenerated = genResult.summary[0]?.red_coins_minted || 0;
    const yellowUsed = walletBefore.yellow_coins - walletAfter.yellow_coins;
    const redRemaining = walletAfter.red_coins;

    console.log(`Summary: Generated ${redGenerated} red coins, used ${yellowUsed} yellow coins for offset, ${redRemaining} red coins remaining`);

    if (yellowUsed > 0 && redRemaining < redGenerated) {
      console.log('✓ Auto-offset worked correctly!');
    } else {
      console.log('✗ Auto-offset did not work as expected');
    }

  } catch (error) {
    console.error('Test failed:', error);
  } finally {
    await sequelize.close();
  }
})();