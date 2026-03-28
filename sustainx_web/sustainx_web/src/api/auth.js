import apiClient from './client.js';

export const login = async (user_id, password) => {
  const response = await apiClient.post('/auth/login', { user_id, password });
  return response.data;
};

export const getProfile = async () => {
  const response = await apiClient.get('/auth/profile');
  return response.data;
};