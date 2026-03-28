const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const { sequelize, testConnection } = require('../config/db');

// Require all models so Sequelize knows about them during sync
const User = require('../models/User');
const EnergyData = require('../models/EnergyData');
const Transaction = require('../models/Transaction');
const MeterReading = require('../models/MeterReading');

const EnergyService = require('../services/EnergyService');

const meterReadings = [
  { user_id: 'USR001', user_type: 'Residential', meter_id: 'MTR-1001', billing_cycle: 1, imports_kwh: 180.5, exports_kwh: 220.2 },
  { user_id: 'USR001', user_type: 'Residential', meter_id: 'MTR-1001', billing_cycle: 2, imports_kwh: 192.0, exports_kwh: 230.3 },
  { user_id: 'USR002', user_type: 'Commercial', meter_id: 'MTR-1002', billing_cycle: 1, imports_kwh: 520.0, exports_kwh: 600.1 },
  { user_id: 'USR002', user_type: 'Commercial', meter_id: 'MTR-1002', billing_cycle: 2, imports_kwh: 540.0, exports_kwh: 620.0 },
  { user_id: 'USR003', user_type: 'Industrial', meter_id: 'MTR-1003', billing_cycle: 1, imports_kwh: 1200.4, exports_kwh: 1450.5 },
  { user_id: 'USR003', user_type: 'Industrial', meter_id: 'MTR-1003', billing_cycle: 2, imports_kwh: 1230.5, exports_kwh: 1480.8 }
];

(async () => {
  try {
    await testConnection();
    await sequelize.sync({ alter: true });

    const result = await EnergyService.processMeterReadings(meterReadings);
    console.log(`Processed ${result.length} meter readings`);
    result.forEach((r) => {
      console.log(`- ${r.reading.user_id} / ${r.reading.billing_cycle}: ${r.result.message}`);
    });

    await sequelize.close();
    process.exit(0);
  } catch (err) {
    console.error('Import failed:', err);
    process.exit(1);
  }
})();
