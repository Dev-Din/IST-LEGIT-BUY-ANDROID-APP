/**
 * M-Pesa OAuth Token Generation
 */

import * as dotenv from "dotenv";
import axios from "axios";
import * as functions from "firebase-functions";
import {AccessTokenResponse, MpesaConfig} from "./types";

// Load environment variables from .env file
dotenv.config();

let cachedToken: {token: string; expiresAt: number} | null = null;

/**
 * Get M-Pesa configuration
 * Priority: Environment variables > Firebase Functions config > Defaults
 */
function getMpesaConfig(): MpesaConfig {
  // First, try environment variables (for local development with emulators)
  const envConsumerKey = process.env.MPESA_CONSUMER_KEY;
  const envConsumerSecret = process.env.MPESA_CONSUMER_SECRET;
  const envPasskey = process.env.MPESA_PASSKEY;
  const envShortcode = process.env.MPESA_SHORTCODE;
  const envBaseUrl = process.env.MPESA_BASE_URL;

  // #region agent log
  functions.logger.info("Loading M-Pesa config", {
    hasEnvConsumerKey: !!envConsumerKey,
    hasEnvConsumerSecret: !!envConsumerSecret,
    hasEnvPasskey: !!envPasskey,
    hasEnvShortcode: !!envShortcode,
    envBaseUrl: envBaseUrl,
    consumerKeyPreview: envConsumerKey ? envConsumerKey.substring(0, 20) + "..." : "missing",
    consumerSecretPreview: envConsumerSecret ? envConsumerSecret.substring(0, 20) + "..." : "missing",
  });
  // #endregion

  if (envConsumerKey && envConsumerSecret && envPasskey && envShortcode) {
    // #region agent log
    functions.logger.info("Using environment variables for M-Pesa config");
    // #endregion
    return {
      consumerKey: envConsumerKey,
      consumerSecret: envConsumerSecret,
      passkey: envPasskey,
      shortcode: envShortcode,
      baseUrl: envBaseUrl || "https://sandbox.safaricom.co.ke",
    };
  }

  // Second, try Firebase Functions config (for production)
  try {
    const config = functions.config().mpesa;
    if (config) {
      return {
        consumerKey: config.consumer_key || "yVcigqegMbip51XGxKZNm5JYf8eVTrFSuQF9rLMi657wjPDP",
        consumerSecret: config.consumer_secret || "u7GKHXpo55Apq6sfbyXj5D9R3YclLxy7OA5jWhZ9PqLfMPB2pDAWFqob1ExFyFC2",
        passkey: config.passkey || "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919",
        shortcode: config.shortcode || "174379",
        baseUrl: config.base_url || "https://sandbox.safaricom.co.ke",
      };
    }
  } catch (error) {
    // functions.config() may not be available in emulator
    functions.logger.warn("Firebase Functions config not available, using defaults");
  }

  // Finally, use defaults (for local development fallback)
  return {
    consumerKey: "yVcigqegMbip51XGxKZNm5JYf8eVTrFSuQF9rLMi657wjPDP",
    consumerSecret: "u7GKHXpo55Apq6sfbyXj5D9R3YclLxy7OA5jWhZ9PqLfMPB2pDAWFqob1ExFyFC2",
    passkey: "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919",
    shortcode: "174379",
    baseUrl: "https://sandbox.safaricom.co.ke",
  };
}

/**
 * Generate OAuth access token for M-Pesa API
 * Caches token until expiration to avoid unnecessary API calls
 */
export async function getAccessToken(): Promise<string> {
  // Return cached token if still valid (with 5 minute buffer)
  if (cachedToken && cachedToken.expiresAt > Date.now() + 5 * 60 * 1000) {
    return cachedToken.token;
  }

  const config = getMpesaConfig();
  const authUrl = `${config.baseUrl}/oauth/v1/generate?grant_type=client_credentials`;

  // #region agent log
  functions.logger.info("Attempting M-Pesa authentication", {
    baseUrl: config.baseUrl,
    authUrl: authUrl,
    hasConsumerKey: !!config.consumerKey,
    hasConsumerSecret: !!config.consumerSecret,
    consumerKeyLength: config.consumerKey?.length || 0,
  });
  // #endregion

  try {
    const response = await axios.get<AccessTokenResponse>(authUrl, {
      auth: {
        username: config.consumerKey,
        password: config.consumerSecret,
      },
      headers: {
        "Content-Type": "application/json",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "Accept": "application/json",
      },
      timeout: 30000, // 30 second timeout (WAF might add delay)
      validateStatus: function (status) {
        return status < 500; // Don't throw on 4xx errors, we'll handle them
      },
    });

    // Check if response is successful
    if (response.status !== 200) {
      throw new Error(`M-Pesa API returned status ${response.status}: ${JSON.stringify(response.data)}`);
    }

    // Check if response data is valid
    if (!response.data || !response.data.access_token) {
      throw new Error(`Invalid response from M-Pesa API: ${JSON.stringify(response.data)}`);
    }

    const accessToken = response.data.access_token;
    const expiresIn = parseInt(response.data.expires_in, 10) * 1000; // Convert to milliseconds

    // #region agent log
    functions.logger.info("M-Pesa authentication successful", {
      tokenLength: accessToken?.length || 0,
      expiresIn: expiresIn,
    });
    // #endregion

    // Cache the token
    cachedToken = {
      token: accessToken,
      expiresAt: Date.now() + expiresIn,
    };

    return accessToken;
  } catch (error: any) {
    // #region agent log
    const errorDetails = {
      message: error?.message || "Unknown error",
      code: error?.code,
      status: error?.response?.status,
      statusText: error?.response?.statusText,
      data: error?.response?.data,
      headers: error?.response?.headers,
      config: {
        url: error?.config?.url,
        method: error?.config?.method,
        auth: error?.config?.auth ? "Present" : "Missing",
      },
    };
    functions.logger.error("Failed to get M-Pesa access token - detailed error", JSON.stringify(errorDetails, null, 2));
    
    // Log the raw response if available
    if (error?.response?.data) {
      functions.logger.error("M-Pesa API Error Response Body", typeof error.response.data === 'string' 
        ? error.response.data 
        : JSON.stringify(error.response.data, null, 2));
    }
    // #endregion
    
    // Provide more helpful error message
    if (error?.response?.status === 400) {
      const errorMsg = error?.response?.data 
        ? (typeof error.response.data === 'string' ? error.response.data : JSON.stringify(error.response.data))
        : "Bad Request - Check credentials and API endpoint";
      throw new Error(`M-Pesa API returned 400 Bad Request: ${errorMsg}`);
    }
    
    throw new Error(`Failed to authenticate with M-Pesa API: ${error?.message || "Unknown error"}`);
  }
}
