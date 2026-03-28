import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Login = () => {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [user_id, setUserId] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    const result = await login(user_id, password);
    if (result.success) {
      navigate('/dashboard');
    } else {
      setError(result.message);
    }
  };

  return (
    <div style={{ backgroundColor: '#f0f4f8', minHeight: '100vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
      <div style={{ width: '420px', backgroundColor: 'white', borderRadius: '14px', border: '1px solid #e2e8f0', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)', padding: '2rem' }}>
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <div style={{ fontFamily: 'Space Grotesk', fontSize: '2rem', fontWeight: 'bold' }}>
            <span style={{ background: 'linear-gradient(to right, #fbbf24, #3b82f6)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>⚡</span>
            <span style={{ color: '#f59e0b' }}>Energi</span>
            <span style={{ color: '#f59e0b' }}>Coin</span>
          </div>
        </div>
        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: '1rem' }}>
            <label style={{ display: 'block', marginBottom: '0.5rem', fontFamily: 'DM Sans' }}>User ID</label>
            <input
              type="text"
              placeholder="e.g. PR001 or C001"
              value={user_id}
              onChange={(e) => setUserId(e.target.value)}
              style={{ width: '100%', padding: '0.5rem', border: '1px solid #d1d5db', borderRadius: '0.375rem', fontFamily: 'DM Sans' }}
            />
          </div>
          <div style={{ marginBottom: '1rem' }}>
            <label style={{ display: 'block', marginBottom: '0.5rem', fontFamily: 'DM Sans' }}>Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              style={{ width: '100%', padding: '0.5rem', border: '1px solid #d1d5db', borderRadius: '0.375rem', fontFamily: 'DM Sans' }}
            />
          </div>
          <button
            type="submit"
            style={{ width: '100%', backgroundColor: '#3b82f6', color: 'white', padding: '0.5rem', border: 'none', borderRadius: '0.375rem', fontFamily: 'DM Sans', cursor: 'pointer' }}
          >
            Sign In
          </button>
          {error && <p style={{ color: 'red', marginTop: '1rem', fontFamily: 'DM Sans' }}>{error}</p>}
        </form>
      </div>
    </div>
  );
};

export default Login;