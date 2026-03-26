# 📋 EnergyPass Backend - Quick Reference Card

## 🚀 Quick Start (30 seconds)

```bash
# 1. Install dependencies
npm install

# 2. Copy environment template
cp .env.example .env

# 3. Start development server (with auto-reload)
npm run dev

# 4. Navigate to
http://localhost:5000
```

---

## 🔌 Core API Endpoints

### Authentication
```
POST   /api/auth/register         # Create account
POST   /api/auth/login            # Login
GET    /api/auth/profile          # Get profile (auth required)
PUT    /api/auth/profile          # Update profile (auth required)
```

### Wallet
```
GET    /api/wallet/info           # Wallet info (auth required)
GET    /api/wallet/balance        # Balance (auth required)
GET    /api/wallet/qr-code        # QR code (auth required)
GET    /api/wallet/leaderboard    # Top users
GET    /api/wallet/rank           # Your rank (auth required)
```

### Energy
```
POST   /api/energy/record         # Record data (auth required)
GET    /api/energy/history        # History (auth required)
GET    /api/energy/stats          # Stats (auth required)
```

### Transactions
```
POST   /api/transactions/transfer     # Transfer coins (auth required)
GET    /api/transactions/history      # All transactions (auth required)
GET    /api/transactions/sent         # Sent (auth required)
GET    /api/transactions/received     # Received (auth required)
```

---

## 📦 Project Structure

```
/models          - Data schemas (User, Transaction, EnergyData)
/controllers     - Request handlers
/services        - Business logic
/routes          - API endpoints
/middleware      - Auth & error handling
/config          - Configuration
/constants       - Constants & messages
server.js        - Main application
```

---

## 💰 Coin System

| Coin | What | Earned When |
|------|------|-------------|
| 🟡 Yellow | Energy produced | User exports energy to grid |
| 🟢 Green | Shared energy | Net surplus available (export > import) |
| 🔴 Red | Consumed | User imports from grid |

**Conversion**: 1 kWh = 10 coins (configurable)

---

## 🔐 Authentication

```javascript
// All protected endpoints need:
Authorization: Bearer JWT_TOKEN

// Get token from:
POST /api/auth/register or login
// Returns: { token: "jwt_token", ... }

// Token expires in: 7 days
```

---

## 🧪 Quick Test Examples

### Register User
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john",
    "email": "john@example.com",
    "password": "pass123",
    "fullName": "John Doe"
  }'
```

### Record Energy
```bash
curl -X POST http://localhost:5000/api/energy/record \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "importedKWh": 10,
    "exportedKWh": 25,
    "conversionRate": 10
  }'
```

### Transfer Coins
```bash
curl -X POST http://localhost:5000/api/transactions/transfer \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "toUserId": "user_id_2",
    "yellowCoins": 50,
    "greenCoins": 25,
    "redCoins": 0
  }'
```

---

## 🌍 Environment Variables

```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/energypass
JWT_SECRET=your_secret_key
JWT_EXPIRATION=7d
DEFAULT_CONVERSION_RATE=10
CORS_ORIGIN=http://localhost:3000
NODE_ENV=development
```

---

## ⚠️ Common Issues & Solutions

| Problem | Solution |
|---------|----------|
| "Cannot connect to MongoDB" | Start MongoDB or check MONGODB_URI in .env |
| "Port 5000 already in use" | Change PORT in .env or kill process on port 5000 |
| "Module not found" | Run `npm install` |
| "Invalid token" | Check token format is "Bearer TOKEN" and not expired |
| "Insufficient balance" | Record energy data first to generate coins |

---

## 📊 Response Format

### Success Response (200/201)
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { /* result data */ }
}
```

### Error Response (400/401/500)
```json
{
  "success": false,
  "message": "Error description",
  "errors": [ /* if applicable */ ]
}
```

---

## 🔄 Data Flow Example

```
1. User registers
   ↓
2. User records: 25 kWh export, 10 kWh import
   ↓
3. System generates:
   - 250 yellow coins (25 × 10)
   - 150 green coins (15 × 10, net surplus)
   - 0 red coins
   - 40 energy score points
   ↓
4. User transfers 50 yellow to friend
   ↓
5. Both users get energy score bonus
```

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| server.js | Entry point |
| .env | Configuration |
| models/*.js | Database schemas |
| controllers/*.js | Request handlers |
| services/*.js | Business logic |
| routes/*.js | API endpoints |
| middleware/auth.js | JWT verification |
| middleware/errorHandler.js | Error handling |

---

## 💡 Important Methods

**Auth**:
- `AuthService.register(username, email, password, fullName)`
- `AuthService.login(email, password)`

**Energy**:
- `EnergyService.recordEnergyData(userId, imported, exported, rate)`
- `EnergyService.getEnergyStats(userId, days)`

**Wallet**:
- `WalletService.getWallet(userId)`
- `WalletService.getLeaderboard(limit)`
- `WalletService.generateQRCode(userId)`

**Transactions**:
- `TransactionService.transferCoins(fromId, toId, yellow, green, red, note)`
- `TransactionService.getTransactionHistory(userId, limit)`

---

## 🛠️ Development Commands

```bash
# Install dependencies
npm install

# Start development server (auto-reload)
npm run dev

# Start production server
npm start

# Check Node version
node --version

# Check npm version
npm --version
```

---

## 📈 Deployment Checklist

- [ ] Update .env for production
- [ ] Change JWT_SECRET to strong value
- [ ] Update MONGODB_URI to production database
- [ ] Set NODE_ENV=production
- [ ] Update CORS_ORIGIN for frontend domain
- [ ] Test all endpoints
- [ ] Deploy to hosting (Heroku, AWS, etc.)
- [ ] Set up monitoring
- [ ] Enable logging
- [ ] Configure backups

---

## 🎯 Performance Tips

- Use MongoDB indexing on frequently queried fields
- Cache leaderboard data if accessed frequently
- Implement rate limiting for production
- Use connection pooling for MongoDB
- Add Redis for session caching
- Implement pagination for large result sets

---

## 🔒 Security Checklist

- [x] Passwords hashed with bcryptjs
- [x] JWT tokens implemented
- [x] Input validation on all routes
- [x] Error handling middleware
- [x] Environment variables for secrets
- [x] CORS protection
- [x] Protected routes with auth middleware
- [ ] Rate limiting (for production)
- [ ] API monitoring (for production)
- [ ] Audit logging (for production)

---

## 📚 Documentation Links

- **Full API Docs**: See README.md
- **Testing Examples**: See TESTING_GUIDE.js
- **Project Overview**: See PROJECT_SUMMARY.md
- **Implementation Details**: See IMPLEMENTATION_DETAILS.md
- **Express.js**: https://expressjs.com
- **Mongoose**: https://mongoosejs.com
- **JWT**: https://jwt.io

---

## ✉️ Response Status Codes

```
200 - OK (successful read/update)
201 - Created (successful creation)
400 - Bad Request (validation error)
401 - Unauthorized (auth required)
403 - Forbidden (permission denied)
404 - Not Found (resource missing)
500 - Server Error (internal error)
```

---

## 📱 Client Authentication Flow

```
1. Client: POST /api/auth/register
           ↓
2. Server: Returns JWT token
           ↓
3. Client: Store token in AsyncStorage/SecureStore
           ↓
4. Client: Include in all requests:
           Authorization: Bearer {token}
           ↓
5. Server: Middleware verifies token
           ↓
6. Client: If token expires, login again
```

---

## 🎓 Learning Resources

- **RESTful APIs**: https://restfulapi.net
- **JWT Guide**: https://jwt.io/introduction
- **MongoDB**: https://docs.mongodb.com
- **Express Guide**: https://expressjs.com/guide
- **Node.js**: https://nodejs.org/docs

---

**Last Updated**: January 2024  
**Version**: 1.0.0  
**Status**: ✅ Production Ready

---

**Questions?** Check README.md for comprehensive documentation!
