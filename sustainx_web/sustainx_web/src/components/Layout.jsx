import React from 'react';
import { NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { FaTachometerAlt, FaCoins, FaSignOutAlt, FaBars, FaBell, FaSearch } from 'react-icons/fa';

const Layout = ({ children }) => {
  const { user, logout } = useAuth();

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      <aside style={{ width: '240px', height: '100vh', backgroundColor: '#0f172a', position: 'fixed', left: 0, top: 0, color: 'white', overflowY: 'auto' }}>
        <div style={{ padding: '1rem', borderBottom: '1px solid #374151' }}>
          <h2 style={{ margin: 0, fontSize: '1.5rem', fontWeight: 'bold' }}>⚡ EnergiCoin</h2>
        </div>
        <nav style={{ padding: '1rem 0' }}>
          <div style={{ marginBottom: '1rem' }}>
            <h3 style={{ margin: '0 1rem', fontSize: '0.875rem', color: '#9ca3af', textTransform: 'uppercase', fontWeight: 'bold' }}>Main</h3>
            <NavLink
              to="/dashboard"
              style={({ isActive }) => ({
                display: 'flex',
                alignItems: 'center',
                padding: '0.5rem 1rem',
                color: isActive ? '#3b82f6' : 'white',
                textDecoration: 'none',
                backgroundColor: isActive ? '#1e293b' : 'transparent'
              })}
            >
              <FaTachometerAlt style={{ marginRight: '0.5rem' }} />
              Dashboard
            </NavLink>
          </div>
          <div style={{ marginBottom: '1rem' }}>
            <h3 style={{ margin: '0 1rem', fontSize: '0.875rem', color: '#9ca3af', textTransform: 'uppercase', fontWeight: 'bold' }}>Coins</h3>
            <NavLink
              to="/coin-pricing"
              style={({ isActive }) => ({
                display: 'flex',
                alignItems: 'center',
                padding: '0.5rem 1rem',
                color: isActive ? '#3b82f6' : 'white',
                textDecoration: 'none',
                backgroundColor: isActive ? '#1e293b' : 'transparent'
              })}
            >
              <FaCoins style={{ marginRight: '0.5rem' }} />
              Coin Pricing
            </NavLink>
          </div>
          <div>
            <h3 style={{ margin: '0 1rem', fontSize: '0.875rem', color: '#9ca3af', textTransform: 'uppercase', fontWeight: 'bold' }}>System</h3>
            {/* Placeholder for system items */}
          </div>
        </nav>
        <div style={{ position: 'absolute', bottom: 0, width: '100%', padding: '1rem', borderTop: '1px solid #374151' }}>
          <p style={{ margin: '0 0 0.5rem 0', fontSize: '0.875rem' }}>{user?.name} ({user?.user_type})</p>
          <button
            onClick={logout}
            style={{
              display: 'flex',
              alignItems: 'center',
              backgroundColor: 'transparent',
              border: 'none',
              color: 'white',
              cursor: 'pointer',
              padding: '0.5rem',
              width: '100%',
              textAlign: 'left'
            }}
          >
            <FaSignOutAlt style={{ marginRight: '0.5rem' }} />
            Logout
          </button>
        </div>
      </aside>
      <div style={{ marginLeft: '240px', flex: 1, display: 'flex', flexDirection: 'column' }}>
        <header style={{ height: '60px', backgroundColor: 'white', borderBottom: '1px solid #e5e7eb', display: 'flex', alignItems: 'center', padding: '0 1rem', position: 'sticky', top: 0, zIndex: 10 }}>
          <FaBars style={{ cursor: 'pointer', marginRight: '1rem' }} />
          <div style={{ position: 'relative', flex: 1, maxWidth: '400px' }}>
            <FaSearch style={{ position: 'absolute', left: '0.5rem', top: '50%', transform: 'translateY(-50%)', color: '#9ca3af' }} />
            <input
              type="text"
              placeholder="Search..."
              style={{
                width: '100%',
                padding: '0.5rem 0.5rem 0.5rem 2rem',
                border: '1px solid #d1d5db',
                borderRadius: '0.375rem',
                outline: 'none'
              }}
            />
          </div>
          <FaBell style={{ cursor: 'pointer', marginLeft: 'auto', marginRight: '1rem' }} />
          <div
            style={{
              width: '40px',
              height: '40px',
              borderRadius: '50%',
              backgroundColor: '#3b82f6',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontWeight: 'bold',
              cursor: 'pointer'
            }}
          >
            {user?.name?.charAt(0).toUpperCase()}
          </div>
        </header>
        <main style={{ flex: 1, padding: '1rem' }}>
          {children}
        </main>
      </div>
    </div>
  );
};

export default Layout;