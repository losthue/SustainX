import React, { useState, useEffect } from 'react';
import { getCoinPrices, saveCoinPrices } from '../api/coinPrices';

const CoinPricing = () => {
  const [yellowPrice, setYellowPrice] = useState(0);
  const [greenPrice, setGreenPrice] = useState(0);
  const [redPrice, setRedPrice] = useState(0);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [note, setNote] = useState('');
  const [saveStatus, setSaveStatus] = useState('idle');
  const [successMessage, setSuccessMessage] = useState('');

  useEffect(() => {
    const fetchPrices = async () => {
      const data = await getCoinPrices();
      setYellowPrice(data.yellow_price);
      setGreenPrice(data.green_price);
      setRedPrice(data.red_price);
      setLoading(false);
    };
    fetchPrices();
  }, []);

  const handleSave = async () => {
    setSaveStatus('saving');
    const result = await saveCoinPrices(yellowPrice, greenPrice, redPrice, note);
    if (result.success) {
      setSaveStatus('saved');
      setSuccessMessage('Prices saved successfully!');
      setTimeout(() => setSuccessMessage(''), 3000);
    } else {
      setSaveStatus('error');
    }
    setShowModal(false);
    setNote('');
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '200px' }}>
        <div>Loading...</div>
      </div>
    );
  }

  return (
    <div>
      <h1>Coin Pricing Control</h1>
      <p>Set the MUR monetary value of each coin · All prices fetched from database at runtime</p>

      <div style={{ backgroundColor: '#0f172a', color: 'white', padding: '1rem', borderRadius: '0.5rem', marginBottom: '1rem' }}>
        <p>🟡 Yellow = Export − Import (net surplus) · 1 kWh = 1 coin</p>
        <p>🟢 Green = Converted from Yellow for transactions · 1:1 ratio</p>
        <p>🔴 Red = Grid import consumed · 1 kWh = 1 coin</p>
        <p>1 Yellow or 1 Green offsets 1 Red (always 1:1)</p>
        <p>Only MUR monetary value differs</p>
      </div>

      <div style={{ display: 'flex', gap: '1rem', marginBottom: '1rem' }}>
        <div style={{ flex: 1, background: 'linear-gradient(to right, #fbbf24, #f59e0b)', color: 'white', padding: '1rem', borderRadius: '0.5rem', textAlign: 'center' }}>
          <h3>Yellow</h3>
          <p>Rs {yellowPrice.toFixed(2)}</p>
        </div>
        <div style={{ flex: 1, background: 'linear-gradient(to right, #10b981, #059669)', color: 'white', padding: '1rem', borderRadius: '0.5rem', textAlign: 'center' }}>
          <h3>Green</h3>
          <p>Rs {greenPrice.toFixed(2)}</p>
        </div>
        <div style={{ flex: 1, background: 'linear-gradient(to right, #ef4444, #dc2626)', color: 'white', padding: '1rem', borderRadius: '0.5rem', textAlign: 'center' }}>
          <h3>Red</h3>
          <p>Rs {redPrice.toFixed(2)}</p>
        </div>
      </div>

      <div style={{ display: 'flex', gap: '1rem', marginBottom: '1rem' }}>
        <div style={{ flex: 1, border: '1px solid #e5e7eb', borderRadius: '0.5rem', padding: '1rem' }}>
          <h3>Yellow Coin</h3>
          <p>Represents net energy surplus from exports</p>
          <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>Offsets Red 1:1</p>
          <div style={{ marginBottom: '1rem' }}>
            <label style={{ marginRight: '0.5rem' }}>Rs</label>
            <input
              type="number"
              step="0.01"
              value={yellowPrice}
              onChange={(e) => setYellowPrice(parseFloat(e.target.value) || 0)}
              style={{ padding: '0.5rem', border: '1px solid #d1d5db', borderRadius: '0.25rem' }}
            />
          </div>
          <div style={{ marginBottom: '1rem' }}>
            <button onClick={() => setYellowPrice(4)} style={{ marginRight: '0.5rem', padding: '0.25rem 0.5rem', backgroundColor: '#e5e7eb', border: 'none', borderRadius: '0.25rem' }}>Rs 4</button>
            <button onClick={() => setYellowPrice(7)} style={{ marginRight: '0.5rem', padding: '0.25rem 0.5rem', backgroundColor: '#e5e7eb', border: 'none', borderRadius: '0.25rem' }}>Rs 7</button>
            <button onClick={() => setYellowPrice(10)} style={{ padding: '0.25rem 0.5rem', backgroundColor: '#e5e7eb', border: 'none', borderRadius: '0.25rem' }}>Rs 10</button>
          </div>
          <div>
            <p>10 coins = Rs {(yellowPrice * 10).toFixed(2)}</p>
            <p>50 coins = Rs {(yellowPrice * 50).toFixed(2)}</p>
            <p>100 coins = Rs {(yellowPrice * 100).toFixed(2)}</p>
          </div>
        </div>

        <div style={{ flex: 1, border: '1px solid #e5e7eb', borderRadius: '0.5rem', padding: '1rem' }}>
          <h3>Green Coin</h3>
          <p>Converted from Yellow for transactions</p>
          <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>Offsets Red 1:1</p>
          <div style={{ marginBottom: '1rem' }}>
            <label style={{ marginRight: '0.5rem' }}>Rs</label>
            <input
              type="number"
              step="0.01"
              value={greenPrice}
              onChange={(e) => setGreenPrice(parseFloat(e.target.value) || 0)}
              style={{ padding: '0.5rem', border: '1px solid #d1d5db', borderRadius: '0.25rem' }}
            />
          </div>
          <div style={{ marginBottom: '1rem' }}>
            <button onClick={() => setGreenPrice(4)} style={{ marginRight: '0.5rem', padding: '0.25rem 0.5rem', backgroundColor: '#e5e7eb', border: 'none', borderRadius: '0.25rem' }}>Rs 4</button>
            <button onClick={() => setGreenPrice(7)} style={{ marginRight: '0.5rem', padding: '0.25rem 0.5rem', backgroundColor: '#e5e7eb', border: 'none', borderRadius: '0.25rem' }}>Rs 7</button>
            <button onClick={() => setGreenPrice(10)} style={{ padding: '0.25rem 0.5rem', backgroundColor: '#e5e7eb', border: 'none', borderRadius: '0.25rem' }}>Rs 10</button>
          </div>
          <div>
            <p>10 coins = Rs {(greenPrice * 10).toFixed(2)}</p>
            <p>50 coins = Rs {(greenPrice * 50).toFixed(2)}</p>
            <p>100 coins = Rs {(greenPrice * 100).toFixed(2)}</p>
          </div>
        </div>

        <div style={{ flex: 1, border: '1px solid #e5e7eb', borderRadius: '0.5rem', padding: '1rem' }}>
          <h3>Red Coin</h3>
          <p>Represents grid import consumption</p>
          <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>Offset by Yellow/Green 1:1</p>
          <div style={{ marginBottom: '1rem' }}>
            <label style={{ marginRight: '0.5rem' }}>Rs</label>
            <input
              type="number"
              step="0.01"
              value={redPrice}
              onChange={(e) => setRedPrice(parseFloat(e.target.value) || 0)}
              style={{ padding: '0.5rem', border: '1px solid #d1d5db', borderRadius: '0.25rem' }}
            />
          </div>
          <div style={{ marginBottom: '1rem' }}>
            <button onClick={() => setRedPrice(4)} style={{ marginRight: '0.5rem', padding: '0.25rem 0.5rem', backgroundColor: '#e5e7eb', border: 'none', borderRadius: '0.25rem' }}>Rs 4</button>
            <button onClick={() => setRedPrice(7)} style={{ marginRight: '0.5rem', padding: '0.25rem 0.5rem', backgroundColor: '#e5e7eb', border: 'none', borderRadius: '0.25rem' }}>Rs 7</button>
            <button onClick={() => setRedPrice(10)} style={{ padding: '0.25rem 0.5rem', backgroundColor: '#e5e7eb', border: 'none', borderRadius: '0.25rem' }}>Rs 10</button>
          </div>
          <div>
            <p>10 coins = Rs {(redPrice * 10).toFixed(2)}</p>
            <p>50 coins = Rs {(redPrice * 50).toFixed(2)}</p>
            <p>100 coins = Rs {(redPrice * 100).toFixed(2)}</p>
          </div>
        </div>
      </div>

      <button
        onClick={() => setShowModal(true)}
        style={{ padding: '0.5rem 1rem', backgroundColor: '#3b82f6', color: 'white', border: 'none', borderRadius: '0.25rem', cursor: 'pointer' }}
      >
        Save Prices
      </button>

      {successMessage && (
        <div style={{ marginTop: '1rem', padding: '0.5rem', backgroundColor: '#d1fae5', color: '#065f46', borderRadius: '0.25rem' }}>
          {successMessage}
        </div>
      )}

      {showModal && (
        <div style={{ position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
          <div style={{ backgroundColor: 'white', padding: '2rem', borderRadius: '0.5rem', maxWidth: '500px', width: '90%' }}>
            <h2>Confirm Price Changes</h2>
            <div style={{ marginBottom: '1rem' }}>
              <p><strong>Yellow:</strong> Rs {yellowPrice.toFixed(2)}</p>
              <p><strong>Green:</strong> Rs {greenPrice.toFixed(2)}</p>
              <p><strong>Red:</strong> Rs {redPrice.toFixed(2)}</p>
            </div>
            <textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Optional note"
              style={{ width: '100%', padding: '0.5rem', border: '1px solid #d1d5db', borderRadius: '0.25rem', marginBottom: '1rem' }}
              rows="3"
            />
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem' }}>
              <button
                onClick={() => setShowModal(false)}
                style={{ padding: '0.5rem 1rem', backgroundColor: '#e5e7eb', border: 'none', borderRadius: '0.25rem', cursor: 'pointer' }}
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                disabled={saveStatus === 'saving'}
                style={{ padding: '0.5rem 1rem', backgroundColor: '#3b82f6', color: 'white', border: 'none', borderRadius: '0.25rem', cursor: 'pointer', opacity: saveStatus === 'saving' ? 0.5 : 1 }}
              >
                {saveStatus === 'saving' ? 'Saving...' : 'Confirm'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CoinPricing;