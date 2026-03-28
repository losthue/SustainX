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

    console.log('Testing generateCoinsForCycle generates yellow coins but NOT green coins...');

    // First, reset wallet and record energy surplus
    await sequelize.query(
      'UPDATE wallets SET yellow_coins = 0, green_coins = 100, red_coins = 0 WHERE user_id = ?',
      { replacements: [testUserId] }
    );

    // Record energy surplus (this should NOT generate coins immediately now)
    console.log('Recording energy surplus (5 kWh import, 20 kWh export = 15 kWh surplus)...');
    const recordResult = await EnergyService.recordReading(testUserId, 5, 20, 999);
    console.log('Record result coins_generated:', recordResult.reading.coins_generated);

    // Check wallet before coin generation
    const walletBefore = await WalletService.getWallet(testUserId);
    console.log('Wallet before generateCoinsForCycle:', {
      yellow: walletBefore.yellow_coins,
      green: walletBefore.green_coins,
      red: walletBefore.red_coins
    });

    // Now generate coins for the cycle
    console.log('Generating coins for cycle 999...');
    const genResult = await EnergyService.generateCoinsForCycle(999);
    console.log('Generate result:', genResult);

    // Check wallet after coin generation
    const walletAfter = await WalletService.getWallet(testUserId);
    console.log('Wallet after generateCoinsForCycle:', {
      yellow: walletAfter.yellow_coins,
      green: walletAfter.green_coins,
      red: walletAfter.red_coins
    });

    const yellowGenerated = walletAfter.yellow_coins - walletBefore.yellow_coins;
    const greenGenerated = walletAfter.green_coins - walletBefore.green_coins;

    console.log(`Summary: Generated ${yellowGenerated} yellow coins, ${greenGenerated} green coins`);

    if (yellowGenerated > 0 && greenGenerated === 0) {
      console.log('✅ SUCCESS: Yellow coins were generated, green coins were NOT generated from energy');
      console.log('   Green coins should only be obtained via marketplace or P2P yellow→green sales');
    } else {
      console.log('❌ FAILURE: Unexpected coin generation behavior');
      console.log(`   Expected: yellow > 0, green = 0`);
      console.log(`   Actual: yellow = ${yellowGenerated}, green = ${greenGenerated}`);
    }

  } catch (error) {
    console.error('Test failed:', error.message);
  } finally {
    await sequelize.close();
  }
})();