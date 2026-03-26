-- MySQL initialization script for SustainX backend
-- Create database if not exists (only if not already in use by Sequelize config)
CREATE DATABASE IF NOT EXISTS sustainx_db;
USE sustainx_db;

-- Meter readings table for user energy imports/exports
CREATE TABLE IF NOT EXISTS meter_readings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  userId VARCHAR(64) NOT NULL,
  userType ENUM('Residential', 'Commercial', 'Industrial') NOT NULL,
  meterId VARCHAR(64) NOT NULL,
  billingCycle VARCHAR(32) NOT NULL,
  imports_kwh FLOAT NOT NULL,
  exports_kwh FLOAT NOT NULL,
  net_kwh FLOAT NOT NULL
);

-- Bulk insert meter reading data from the provided dataset
INSERT INTO meter_readings (userId, userType, meterId, billingCycle, imports_kwh, exports_kwh, net_kwh) VALUES
('12-12-2024-06', 'Residential', 'MTR-1001', '2024-06-01 to 2024-06-30', 180.5, 220.2, 39.7),
('12-12-2024-06', 'Residential', 'MTR-1001', '2024-07-01 to 2024-07-30', 192.0, 230.3, 38.3),
('12-13-2024-06', 'Commercial',  'MTR-1002', '2024-06-01 to 2024-06-30', 520.0, 600.1, 80.1),
('12-13-2024-06', 'Commercial',  'MTR-1002', '2024-07-01 to 2024-07-30', 540.0, 620.0, 80.0),
('12-14-2024-06', 'Industrial',  'MTR-1003', '2024-06-01 to 2024-06-30', 1200.4, 1450.5, 250.1),
('12-14-2024-06', 'Industrial',  'MTR-1003', '2024-07-01 to 2024-07-30', 1230.5, 1480.8, 250.3);
