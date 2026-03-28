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

    console.log('Testing that green coins are NOT generated from energy surplus...');

    // First, set wallet to known state
    await sequelize.query(
      'UPDATE wallets SET yellow_coins = 0, green_coins = 100, red_coins = 0 WHERE user_id = ?',
      { replacements: [testUserId] }
    );
    console.log('Set user PR001 to have 0 yellow coins, 100 green coins, and 0 red coins');

    // Check wallet before
    const walletBefore = await WalletService.getWallet(testUserId);
    console.log('Wallet before energy recording:', {
      yellow: walletBefore.yellow_coins,
      green: walletBefore.green_coins,
      red: walletBefore.red_coins
    });

    // Record energy with surplus (should generate yellow coins but NOT green coins)
    console.log('Recording energy surplus (5 kWh import, 20 kWh export = 15 kWh surplus)...');
    const result = await EnergyService.recordReading(testUserId, 5, 20, 999); // net +15 kWh

    console.log('Record result:', result);
    console.log('Coins generated:', result.reading.coins_generated);

    // Check wallet after
    const walletAfter = await WalletService.getWallet(testUserId);
    console.log('Wallet after energy recording:', {
      yellow: walletAfter.yellow_coins,
      green: walletAfter.green_coins,
      red: walletAfter.red_coins
    });

    const yellowGenerated = result.reading.coins_generated.yellow;
    const greenGenerated = result.reading.coins_generated.green;
    const greenBefore = walletBefore.green_coins;
    const greenAfter = walletAfter.green_coins;

    console.log(`Summary: Generated ${yellowGenerated} yellow coins, ${greenGenerated} green coins`);

    if (greenAfter === greenBefore && greenGenerated === 0) {
      console.log('✅ SUCCESS: Green coins were NOT generated from energy surplus');
      console.log('   Green coins should only be obtained via marketplace or P2P yellow→green sales');
    } else {
      console.log('❌ FAILURE: Green coins were generated when they should not have been');
      console.log(`   Green before: ${greenBefore}, Green after: ${greenAfter}, Generated: ${greenGenerated}`);
    }

  } catch (error) {
    console.error('Test failed:', error.message);
  } finally {
    await sequelize.close();
  }
})();