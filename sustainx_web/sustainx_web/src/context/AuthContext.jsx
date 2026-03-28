import React, { createContext, useContext, useState, useEffect } from 'react';
import { login } from '../api/auth.js';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);

  useEffect(() => {
    const storedToken = localStorage.getItem('sustainx_token');
    const storedUser = localStorage.getItem('sustainx_user');
    if (storedToken && storedUser) {
      setToken(storedToken);
      setUser(JSON.parse(storedUser));
    }
  }, []);

  const handleLogin = async (user_id, password) => {
    try {
      const response = await login(user_id, password);
      if (response.success) {
        localStorage.setItem('sustainx_token', response.token);
        localStorage.setItem('sustainx_user', JSON.stringify(response.user));
        setToken(response.token);
        setUser(response.user);
        return { success: true };
      } else {
        return { success: false, message: 'Login failed' };
      }
    } catch (error) {
      return { success: false, message: error.response?.data?.message || 'Login error' };
    }
  };

  const logout = () => {
    localStorage.removeItem('sustainx_token');
    localStorage.removeItem('sustainx_user');
    setToken(null);
    setUser(null);
  };

  const isAuthenticated = !!token;

  return (
    <AuthContext.Provider value={{ user, token, login: handleLogin, logout, isAuthenticated }}>
      {children}
    </AuthContext.Provider>
  );
};