/**
 * M-Pesa OAuth Token Generation
 */

import axios from "axios";
import * as functions from "firebase-functions";
import {AccessTokenResponse, MpesaConfig} from "./types";

let cachedToken: {token: string; expiresAt: number} | null = null;

/**
 * Get M-Pesa configuration from Firebase Functions config
 */
function getMpesaConfig(): MpesaConfig {
  const config = functions.config().mpesa;
  if (!config) {
    throw new Error("M-Pesa configuration not found");
  }

  return {
    consumerKey: config.consumer_key || "yVcigqegMbip51XGxKZNm5JYf8eVTrFSuQF9rLMi657wjPDP",
    consumerSecret: config.consumer_secret || "u7GKHXpo55Apq6sfbyXj5D9R3YclLxy7OA5jWhZ9PqLfMPB2pDAWFqob1ExFyFC2",
    passkey: config.passkey || "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919",
    shortcode: config.shortcode || "174379",
    baseUrl: config.base_url || "https://sandbox.safaricom.co.ke",
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

  try {
    const response = await axios.get<AccessTokenResponse>(authUrl, {
      auth: {
        username: config.consumerKey,
        password: config.consumerSecret,
      },
      headers: {
        "Content-Type": "application/json",
      },
    });

    const accessToken = response.data.access_token;
    const expiresIn = parseInt(response.data.expires_in, 10) * 1000; // Convert to milliseconds

    // Cache the token
    cachedToken = {
      token: accessToken,
      expiresAt: Date.now() + expiresIn,
    };

    return accessToken;
  } catch (error) {
    functions.logger.error("Failed to get M-Pesa access token", error);
    throw new Error("Failed to authenticate with M-Pesa API");
  }
}
