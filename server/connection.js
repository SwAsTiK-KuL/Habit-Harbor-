require('dotenv').config();
const { MongoClient } = require('mongodb');

async function testConnection() {
  console.log('🔍 Testing MongoDB connection...');
  console.log('📋 Connection string (hidden password):');
  console.log(process.env.MONGODB_URI.replace(/:([^@]+)@/, ':****@'));

  const client = new MongoClient(process.env.MONGODB_URI);

  try {
    await client.connect();
    console.log('✅ SUCCESS! Connected to MongoDB Atlas!');

    const db = client.db('habit_harbor');
    console.log('✅ Database "habit_harbor" is ready!');

    // Test insert
    await db.collection('test').insertOne({
      message: 'Hello from Node.js!',
      timestamp: new Date()
    });
    console.log('✅ Test write successful!');

    // Test read
    const doc = await db.collection('test').findOne({});
    console.log('✅ Test read successful:', doc.message);

    // Cleanup
    await db.collection('test').deleteMany({});
    console.log('✅ Cleanup done!');

    console.log('🎉 MongoDB Atlas is working perfectly!');

  } catch (error) {
    console.error('❌ CONNECTION FAILED!');
    console.error('Error:', error.message);

    if (error.message.includes('bad auth')) {
      console.error('');
      console.error('💡 SOLUTION: Your password has special characters!');
      console.error('   Either:');
      console.error('   1. URL encode the @ as %40 in your connection string');
      console.error('   2. Change your MongoDB password to remove @ symbol');
    }
  } finally {
    await client.close();
  }
}

testConnection();