import apiClient from './client.js';

export const getCoinPrices = async () => {
  // TODO: wire to backend route
  return { yellow_price: 4.00, green_price: 7.00, red_price: 10.00 };
};

export const saveCoinPrices = async (yellow_price, green_price, red_price, note) => {
  // TODO: wire to backend route
  return { success: true };
};