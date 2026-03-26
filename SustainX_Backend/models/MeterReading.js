const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const MeterReading = sequelize.define('MeterReading', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  userId: { type: DataTypes.STRING, allowNull: false },
  userType: { type: DataTypes.ENUM('Residential', 'Commercial', 'Industrial'), allowNull: false },
  meterId: { type: DataTypes.STRING, allowNull: false },
  billingCycle: { type: DataTypes.STRING, allowNull: false },
  imports_kwh: { type: DataTypes.FLOAT, allowNull: false },
  exports_kwh: { type: DataTypes.FLOAT, allowNull: false },
  net_kwh: { type: DataTypes.FLOAT, allowNull: false },
}, {
  tableName: 'meter_readings',
  timestamps: false,
});

module.exports = MeterReading;
