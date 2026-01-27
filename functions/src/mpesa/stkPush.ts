/**
 * M-Pesa STK Push Implementation
 */

import * as dotenv from "dotenv";
import axios from "axios";
import * as functions from "firebase-functions";
import {getAccessToken} from "./auth";
import {STKPushRequest, STKPushResponse, MpesaConfig} from "./types";

// Load environment variables from .env file
dotenv.config();

/**
 * Get M-Pesa configuration
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
 * Generate password for STK Push (Base64 encoded: Shortcode + Passkey + Timestamp)
 */
function generatePassword(shortcode: string, passkey: string): string {
  const timestamp = new Date()
    .toISOString()
    .replace(/[^0-9]/g, "")
    .slice(0, -3); // Format: YYYYMMDDHHmmss
  const passwordString = `${shortcode}${passkey}${timestamp}`;
  return Buffer.from(passwordString).toString("base64");
}

/**
 * Get callback URL for M-Pesa
 * Supports both production and local development with ngrok
 */
function getCallbackUrl(): string {
  // Check for ngrok URL in environment variable (for local development)
  const ngrokUrl = process.env.NGROK_URL;
  if (ngrokUrl) {
    // Remove trailing slash if present
    const cleanUrl = ngrokUrl.replace(/\/$/, '');
    return `${cleanUrl}/mpesaCallback`;
  }

  // Production: Use Firebase Cloud Functions URL
  const projectId = process.env.GCLOUD_PROJECT || functions.config().project?.id;
  const region = process.env.FUNCTION_REGION || "us-central1";
  
  // Construct callback URL
  // Format: https://[region]-[project-id].cloudfunctions.net/mpesaCallback
  return `https://${region}-${projectId}.cloudfunctions.net/mpesaCallback`;
}

/**
 * Initiate STK Push payment request
 */
export async function initiateSTKPush(
  phoneNumber: string,
  amount: number,
  orderId: string
): Promise<STKPushResponse> {
  try {
    const config = getMpesaConfig();
    const accessToken = await getAccessToken();
    const timestamp = new Date()
      .toISOString()
      .replace(/[^0-9]/g, "")
      .slice(0, -3); // Format: YYYYMMDDHHmmss
    const password = generatePassword(config.shortcode, config.passkey);
    const callbackUrl = getCallbackUrl();

    const stkPushRequest: STKPushRequest = {
      BusinessShortCode: config.shortcode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: "CustomerPayBillOnline",
      Amount: Math.round(amount), // M-Pesa requires integer amount
      PartyA: phoneNumber,
      PartyB: config.shortcode,
      PhoneNumber: phoneNumber,
      CallBackURL: callbackUrl,
      AccountReference: orderId,
      TransactionDesc: `Payment for order ${orderId}`,
    };

    const stkPushUrl = `${config.baseUrl}/mpesa/stkpush/v1/processrequest`;

    functions.logger.info("Initiating STK Push", {
      phoneNumber,
      amount,
      orderId,
      callbackUrl,
    });

    const response = await axios.post<STKPushResponse>(
      stkPushUrl,
      stkPushRequest,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
      }
    );

    if (response.data.ResponseCode !== "0") {
      throw new Error(
        `STK Push failed: ${response.data.ResponseDescription}`
      );
    }

    functions.logger.info("STK Push initiated successfully", {
      CheckoutRequestID: response.data.CheckoutRequestID,
      MerchantRequestID: response.data.MerchantRequestID,
    });

    return response.data;
  } catch (error) {
    functions.logger.error("Failed to initiate STK Push", error);
    if (axios.isAxiosError(error)) {
      throw new Error(
        `M-Pesa API error: ${error.response?.data?.errorMessage || error.message}`
      );
    }
    throw error;
  }
}
