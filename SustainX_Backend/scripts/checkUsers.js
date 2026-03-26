const { testConnection, sequelize } = require('../config/db');
const User = require('../models/User');

(async () => {
  try {
    await testConnection();
    const count = await User.count();
    console.log('user count', count);
    const user = await User.findOne({ where: { email: 'test@sustainx.local' } });
    console.log('user', user ? user.get() : 'none');
    await sequelize.close();
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
})();
