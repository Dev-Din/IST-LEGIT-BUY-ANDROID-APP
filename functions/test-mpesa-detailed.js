/**
 * Detailed M-Pesa API Diagnostic Test
 */

require('dotenv').config();
const axios = require('axios');

const CONSUMER_KEY = process.env.MPESA_CONSUMER_KEY || "yVcigqegMbip51XGxKZNm5JYf8eVTrFSuQF9rLMi657wjPDP";
const CONSUMER_SECRET = process.env.MPESA_CONSUMER_SECRET || "u7GKHXpo55Apq6sfbyXj5D9R3YclLxy7OA5jWhZ9PqLfMPB2pDAWFqob1ExFyFC2";
const BASE_URL = process.env.MPESA_BASE_URL || "https://sandbox.safaricom.co.ke";

console.log("=== Detailed M-Pesa API Diagnostic ===");
console.log("Consumer Key:", CONSUMER_KEY);
console.log("Consumer Secret:", CONSUMER_SECRET.substring(0, 20) + "...");
console.log("Base URL:", BASE_URL);
console.log("");

async function testWithDetailedLogging() {
  const authUrl = `${BASE_URL}/oauth/v1/generate?grant_type=client_credentials`;
  
  console.log("Testing URL:", authUrl);
  console.log("");
  
  try {
    const response = await axios.get(authUrl, {
      auth: {
        username: CONSUMER_KEY,
        password: CONSUMER_SECRET,
      },
      headers: {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "application/json",
      },
      timeout: 30000,
      validateStatus: () => true, // Don't throw on any status
    });
    
    console.log("Response Status:", response.status);
    console.log("Response Headers:", JSON.stringify(response.headers, null, 2));
    console.log("Response Data:", JSON.stringify(response.data, null, 2));
    
    if (response.status === 200) {
      console.log("\n✅ SUCCESS! Access Token:", response.data.access_token?.substring(0, 30) + "...");
    } else {
      console.log("\n❌ FAILED!");
      console.log("Status:", response.status);
      console.log("Status Text:", response.statusText);
      
      // Try to parse error message
      if (typeof response.data === 'string') {
        console.log("Error Response (String):", response.data);
      } else {
        console.log("Error Response (JSON):", JSON.stringify(response.data, null, 2));
      }
    }
  } catch (error) {
    console.log("\n❌ EXCEPTION!");
    console.log("Error Message:", error.message);
    console.log("Error Code:", error.code);
    
    if (error.response) {
      console.log("Response Status:", error.response.status);
      console.log("Response Headers:", JSON.stringify(error.response.headers, null, 2));
      console.log("Response Data:", JSON.stringify(error.response.data, null, 2));
    } else if (error.request) {
      console.log("No response received. Request:", error.request);
    }
  }
}

testWithDetailedLogging();
