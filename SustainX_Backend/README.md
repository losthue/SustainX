# EnergyPass Backend

A Node.js backend application for the EnergyPass mobile application. This system transforms real-world energy data into meaningful digital value through a coin-based economy system.

## 🌟 Features

- **User Authentication**: JWT-based secure login and registration
- **Wallet Management**: Track Yellow, Green, and Red coins
- **Energy Conversion**: Convert kWh data into digital coins automatically
- **Peer-to-Peer Transfers**: Secure coin transfers between users
- **QR Code Generation**: Easy wallet sharing via QR codes
- **Gamification**: Energy score system with leaderboards
- **Real-time Transactions**: Track all user transactions
- **Energy Analytics**: Historical energy data and statistics

## 🏗️ Project Structure

```
SustainX_Backend/
├── models/
│   ├── User.js              # User data model with wallet info
│   ├── Transaction.js       # Transaction history model
│   └── EnergyData.js        # Energy import/export data model
├── controllers/
│   ├── AuthController.js    # Authentication logic
│   ├── WalletController.js  # Wallet operations
│   ├── EnergyController.js  # Energy data processing
│   └── TransactionController.js  # Transaction handling
├── routes/
│   ├── authRoutes.js        # Auth endpoints
│   ├── walletRoutes.js      # Wallet endpoints
│   ├── energyRoutes.js      # Energy endpoints
│   └── transactionRoutes.js # Transaction endpoints
├── services/
│   ├── AuthService.js       # Authentication business logic
│   ├── WalletService.js     # Wallet operations service
│   ├── EnergyService.js     # Energy conversion logic
│   └── TransactionService.js # Transaction handling service
├── middleware/
│   ├── auth.js              # JWT verification middleware
│   └── errorHandler.js      # Error handling middleware
├── constants/
│   └── constants.js         # Application constants
├── config/
│   └── config.js            # Configuration management
├── server.js                # Main Express application
├── package.json             # Dependencies
├── .env                     # Environment variables
└── README.md               # Documentation
```

## 🚀 Getting Started

### Prerequisites

- **Node.js** (v14 or higher)
- **MongoDB** (local or MongoDB Atlas)
- **npm** or **yarn**

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd SustainX_Backend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Configure environment variables**:
   - Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   - Update `.env` with your configuration:
     ```env
     MONGODB_URI=mongodb://localhost:27017/energypass
     JWT_SECRET=your_secret_key
     PORT=5000
     ```

4. **Start MongoDB** (if running locally):
   ```bash
   mongod
   ```

### Running the Application

**Development Mode** (with auto-reload):
```bash
npm run dev
```

**Production Mode**:
```bash
npm start
```

The server will start at `http://localhost:5000`

## 📚 API Documentation

### Base URL
```
http://localhost:5000/api
```

### Authentication Endpoints

#### Register User
```
POST /auth/register
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "fullName": "John Doe"
}

Response:
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": "user_id",
    "username": "john_doe",
    "email": "john@example.com",
    "walletAddress": "wallet_..."
  },
  "token": "jwt_token"
}
```

#### Login User
```
POST /auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securePassword123"
}

Response:
{
  "success": true,
  "message": "Login successful",
  "user": {...},
  "token": "jwt_token"
}
```

#### Get User Profile
```
GET /auth/profile
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": {
    "userId": "user_id",
    "username": "john_doe",
    "walletAddress": "wallet_...",
    "balances": {
      "yellowCoins": 100,
      "greenCoins": 50,
      "redCoins": 25
    },
    "totalBalance": 175,
    "energyScore": 450
  }
}
```

### Wallet Endpoints

#### Get Wallet Info
```
GET /wallet/info
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": {
    "userId": "user_id",
    "username": "john_doe",
    "walletAddress": "wallet_...",
    "balances": {
      "yellowCoins": 100,
      "greenCoins": 50,
      "redCoins": 25
    },
    "totalBalance": 175,
    "energyScore": 450
  }
}
```

#### Get Wallet Balance
```
GET /wallet/balance
Authorization: Bearer {token}
```

#### Generate QR Code
```
GET /wallet/qr-code
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": {
    "qrCodeUrl": "data:image/png;base64,...",
    "walletAddress": "wallet_...",
    "username": "john_doe"
  }
}
```

#### Get Leaderboard (by Energy Score)
```
GET /wallet/leaderboard?limit=10
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": [
    {
      "rank": 1,
      "username": "top_user",
      "energyScore": 1000,
      "balances": {...},
      "totalBalance": 500,
      "profileImage": "url"
    },
    ...
  ]
}
```

#### Get User Rank
```
GET /wallet/rank
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": {
    "username": "john_doe",
    "rank": 15,
    "energyScore": 450,
    "totalCoins": 175,
    "percentile": 85.5
  }
}
```

### Energy Endpoints

#### Record Energy Data
```
POST /energy/record
Authorization: Bearer {token}
Content-Type: application/json

{
  "importedKWh": 10,
  "exportedKWh": 25,
  "conversionRate": 10
}

Response:
{
  "success": true,
  "message": "Energy data processed successfully",
  "energyData": {
    "importedKWh": 10,
    "exportedKWh": 25,
    "netEnergy": 15,
    "coinsGenerated": {
      "yellowCoins": 250,
      "greenCoins": 150,
      "redCoins": 0
    }
  },
  "userWallet": {...}
}
```

#### Get Energy History
```
GET /energy/history?limit=30
Authorization: Bearer {token}

Response:
{
  "success": true,
  "data": [
    {
      "_id": "energy_id",
      "user": "user_id",
      "importedKWh": 10,
      "exportedKWh": 25,
      "netEnergy": 15,
      "yellowCoinsEarned": 250,
      "greenCoinsGenerated": 150,
      "redCoinsIncurred": 0,
      "measurementDate": "2024-01-15",
      "status": "processed"
    },
    ...
  ]
}
```

#### Get Energy Statistics
```
GET /energy/stats?days=30
Authorization: Bearer {token}

Response:
{
  "success": true,
  "period": "30 days",
  "data": {
    "totalImported": 300,
    "totalExported": 750,
    "totalYellowCoins": 7500,
    "totalGreenCoins": 4500,
    "totalRedCoins": 200,
    "averageNetEnergy": 15,
    "dataPoints": 30
  }
}
```

### Transaction Endpoints

#### Transfer Coins
```
POST /transactions/transfer
Authorization: Bearer {token}
Content-Type: application/json

{
  "toUserId": "recipient_user_id",
  "yellowCoins": 50,
  "greenCoins": 25,
  "redCoins": 10,
  "note": "Payment for energy services"
}

Response:
{
  "success": true,
  "message": "Transfer completed successfully",
  "transaction": {
    "transactionId": "transaction_id",
    "from": "john_doe",
    "to": "jane_doe",
    "coinsTransferred": {
      "yellow": 50,
      "green": 25,
      "red": 10
    },
    "totalAmount": 85,
    "timestamp": "2024-01-15T10:30:00Z"
  },
  "senderBalance": {...},
  "receiverBalance": {...}
}
```

#### Get Transaction History
```
GET /transactions/history?limit=50
Authorization: Bearer {token}

Response:
{
  "success": true,
  "count": 5,
  "data": [
    {
      "_id": "transaction_id",
      "fromUser": {...},
      "toUser": {...},
      "yellowCoinsTransferred": 50,
      "greenCoinsTransferred": 25,
      "redCoinsTransferred": 10,
      "totalAmount": 85,
      "transactionType": "transfer",
      "status": "completed",
      "createdAt": "2024-01-15T10:30:00Z"
    },
    ...
  ]
}
```

#### Get Sent Transactions
```
GET /transactions/sent?limit=30
Authorization: Bearer {token}
```

#### Get Received Transactions
```
GET /transactions/received?limit=30
Authorization: Bearer {token}
```

## 💰 Coin System

### Yellow Coins (Energy Contribution)
- Represents energy produced/exported by the user
- Earned when user exports energy to the grid
- Value: 1 kWh = 10 Yellow Coins (configurable)

### Green Coins (Usable Shared Energy)
- Represents solar energy available for others to use
- Converted from exported energy
- Reflects net positive energy contribution

### Red Coins (Energy Consumption)
- Represents energy consumed from the grid
- Earned/incurred when user imports energy
- Tracks non-renewable energy usage

## 🔄 Coin Flow Example

1. **User exports 25 kWh and imports 10 kWh**
   - Net Energy = 25 - 10 = 15 kWh (producer)
   - Yellow Coins = 25 × 10 = 250 coins
   - Green Coins = 15 × 10 = 150 coins
   - Red Coins = 0

2. **User transfers coins to another user**
   - Coins deducted from sender
   - Coins added to receiver
   - Both users earn energy score points

## 🛡️ Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: bcryptjs for secure password storage
- **Input Validation**: All inputs validated and sanitized
- **Error Handling**: Comprehensive error handling middleware
- **Environment Variables**: Sensitive data in .env files
- **CORS Protection**: Cross-origin requests configured

## 📊 Database Schema

### User Collection
```javascript
{
  _id: ObjectId,
  username: String (unique),
  email: String (unique),
  password: String (hashed),
  yellowCoins: Number,
  greenCoins: Number,
  redCoins: Number,
  energyScore: Number,
  walletAddress: String (unique),
  transactions: [ObjectId],
  fullName: String,
  profileImage: String,
  createdAt: Date,
  updatedAt: Date
}
```

### Transaction Collection
```javascript
{
  _id: ObjectId,
  fromUser: ObjectId (ref: User),
  toUser: ObjectId (ref: User),
  yellowCoinsTransferred: Number,
  greenCoinsTransferred: Number,
  redCoinsTransferred: Number,
  totalAmount: Number,
  transactionType: String,
  status: String,
  createdAt: Date,
  completedAt: Date
}
```

### EnergyData Collection
```javascript
{
  _id: ObjectId,
  user: ObjectId (ref: User),
  importedKWh: Number,
  exportedKWh: Number,
  netEnergy: Number,
  yellowCoinsEarned: Number,
  greenCoinsGenerated: Number,
  redCoinsIncurred: Number,
  conversionRate: Number,
  measurementDate: Date,
  status: String,
  createdAt: Date
}
```

## 🧪 Testing the API

### Using cURL

**Register a user:**
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "fullName": "Test User"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

**Record energy data:**
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

## 📈 Future Enhancements

- [ ] Real-time WebSocket updates for wallet changes
- [ ] Email notifications for transactions
- [ ] SMS notifications
- [ ] Advanced analytics and reporting
- [ ] Admin dashboard
- [ ] Energy trading marketplace
- [ ] Integration with IoT devices
- [ ] Mobile push notifications
- [ ] Rate limiting and API throttling
- [ ] Unit and integration tests

## 🚀 Deployment

### Deployment to Heroku

1. **Create Heroku app:**
   ```bash
   heroku create your-app-name
   ```

2. **Set environment variables:**
   ```bash
   heroku config:set JWT_SECRET=your_secret
   heroku config:set MONGODB_URI=your_mongodb_uri
   ```

3. **Deploy:**
   ```bash
   git push heroku main
   ```

### Deployment to AWS/GCP/Azure

See respective cloud provider documentation for Node.js deployment.

## 📝 API Client Libraries

You can generate API client libraries using:
- [OpenAPI Generator](https://openapi-generator.tech/)
- [Swagger Codegen](https://swagger.io/tools/swagger-codegen/)

## 🤝 Contributing

1. Create a feature branch
2. Commit your changes
3. Push to the branch
4. Create a Pull Request

## 📄 License

This project is licensed under the ISC License.

## 📞 Support

For support, please contact the development team or open an issue in the repository.

## 🙏 Acknowledgments

- Built with Express.js and MongoDB
- Security powered by JWT and bcryptjs
- QR codes generated with qrcode package

---

**Happy Coding! 🚀**
