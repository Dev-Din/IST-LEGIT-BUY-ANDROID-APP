/**
 * Test script to debug M-Pesa API calls
 */

require('dotenv').config();
const axios = require('axios');

const CONSUMER_KEY = process.env.MPESA_CONSUMER_KEY || "yVcigqegMbip51XGxKZNm5JYf8eVTrFSuQF9rLMi657wjPDP";
const CONSUMER_SECRET = process.env.MPESA_CONSUMER_SECRET || "u7GKHXpo55Apq6sfbyXj5D9R3YclLxy7OA5jWhZ9PqLfMPB2pDAWFqob1ExFyFC2";
const BASE_URL = process.env.MPESA_BASE_URL || "https://sandbox.safaricom.co.ke";
const SHORTCODE = process.env.MPESA_SHORTCODE || "174379";
const PASSKEY = process.env.MPESA_PASSKEY || "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919";

console.log("=== M-Pesa API Test ===");
console.log("Consumer Key:", CONSUMER_KEY.substring(0, 20) + "...");
console.log("Consumer Secret:", CONSUMER_SECRET.substring(0, 20) + "...");
console.log("Base URL:", BASE_URL);
console.log("Shortcode:", SHORTCODE);
console.log("");

// Test 1: Get Access Token - Try different methods
async function testAccessToken() {
  console.log("1. Testing Access Token Generation...");
  const authUrl = `${BASE_URL}/oauth/v1/generate?grant_type=client_credentials`;
  
  // Try Method 1: Basic Auth with axios
  console.log("\n   Method 1: Basic Auth with axios");
  try {
    const response = await axios.get(authUrl, {
      auth: {
        username: CONSUMER_KEY,
        password: CONSUMER_SECRET,
      },
      headers: {
        "Content-Type": "application/json",
      },
      timeout: 10000,
    });
    
    console.log("✅ Access Token Success!");
    console.log("Token:", response.data.access_token.substring(0, 20) + "...");
    console.log("Expires In:", response.data.expires_in);
    return response.data.access_token;
  } catch (error) {
    console.log("❌ Method 1 Failed!");
    console.log("Status:", error.response?.status);
    console.log("Status Text:", error.response?.statusText);
    console.log("Response Data:", JSON.stringify(error.response?.data, null, 2));
    console.log("Error Message:", error.message);
  }
  
  // Try Method 2: Manual Basic Auth header
  console.log("\n   Method 2: Manual Basic Auth header");
  try {
    const credentials = Buffer.from(`${CONSUMER_KEY}:${CONSUMER_SECRET}`).toString('base64');
    const response = await axios.get(authUrl, {
      headers: {
        "Authorization": `Basic ${credentials}`,
        "Content-Type": "application/json",
      },
      timeout: 10000,
    });
    
    console.log("✅ Access Token Success!");
    console.log("Token:", response.data.access_token.substring(0, 20) + "...");
    console.log("Expires In:", response.data.expires_in);
    return response.data.access_token;
  } catch (error) {
    console.log("❌ Method 2 Failed!");
    console.log("Status:", error.response?.status);
    console.log("Status Text:", error.response?.statusText);
    console.log("Response Data:", JSON.stringify(error.response?.data, null, 2));
    console.log("Error Message:", error.message);
  }
  
  // Try Method 3: Without Content-Type header
  console.log("\n   Method 3: Without Content-Type header");
  try {
    const response = await axios.get(authUrl, {
      auth: {
        username: CONSUMER_KEY,
        password: CONSUMER_SECRET,
      },
      timeout: 10000,
    });
    
    console.log("✅ Access Token Success!");
    console.log("Token:", response.data.access_token.substring(0, 20) + "...");
    console.log("Expires In:", response.data.expires_in);
    return response.data.access_token;
  } catch (error) {
    console.log("❌ Method 3 Failed!");
    console.log("Status:", error.response?.status);
    console.log("Status Text:", error.response?.statusText);
    console.log("Response Data:", JSON.stringify(error.response?.data, null, 2));
    console.log("Error Message:", error.message);
    throw new Error("All authentication methods failed. Credentials may be invalid or expired.");
  }
}

// Test 2: Test STK Push
async function testSTKPush(accessToken) {
  console.log("\n2. Testing STK Push...");
  
  const phoneNumber = "254719286858";
  const amount = 1;
  const timestamp = new Date()
    .toISOString()
    .replace(/[^0-9]/g, "")
    .slice(0, -3);
  const passwordString = `${SHORTCODE}${PASSKEY}${timestamp}`;
  const password = Buffer.from(passwordString).toString("base64");
  const callbackUrl = process.env.NGROK_URL 
    ? `${process.env.NGROK_URL.replace(/\/$/, '')}/mpesaCallback`
    : "https://example.com/callback";
  
  const stkUrl = `${BASE_URL}/mpesa/stkpush/v1/processrequest`;
  
  const requestBody = {
    BusinessShortCode: SHORTCODE,
    Password: password,
    Timestamp: timestamp,
    TransactionType: "CustomerPayBillOnline",
    Amount: amount,
    PartyA: phoneNumber,
    PartyB: SHORTCODE,
    PhoneNumber: phoneNumber,
    CallBackURL: callbackUrl,
    AccountReference: "TEST123",
    TransactionDesc: "Test Payment",
  };
  
  console.log("Request URL:", stkUrl);
  console.log("Request Body:", JSON.stringify(requestBody, null, 2));
  
  try {
    const response = await axios.post(stkUrl, requestBody, {
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      timeout: 10000,
    });
    
    console.log("✅ STK Push Success!");
    console.log("Response:", JSON.stringify(response.data, null, 2));
    return response.data;
  } catch (error) {
    console.log("❌ STK Push Failed!");
    console.log("Status:", error.response?.status);
    console.log("Status Text:", error.response?.statusText);
    console.log("Response Data:", JSON.stringify(error.response?.data, null, 2));
    console.log("Error Message:", error.message);
    throw error;
  }
}

// Run tests
async function runTests() {
  try {
    const accessToken = await testAccessToken();
    await testSTKPush(accessToken);
    console.log("\n✅ All tests passed!");
  } catch (error) {
    console.log("\n❌ Tests failed!");
    process.exit(1);
  }
}

runTests();
