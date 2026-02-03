"use strict";
/**
 * M-Pesa STK Push Implementation
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.initiateSTKPush = initiateSTKPush;
const dotenv = __importStar(require("dotenv"));
const axios_1 = __importDefault(require("axios"));
const functions = __importStar(require("firebase-functions"));
const auth_1 = require("./auth");
// Load environment variables from .env file
dotenv.config();
/**
 * Get M-Pesa configuration
 * Priority: Environment variables > Firebase Functions config > Defaults
 */
function getMpesaConfig() {
    // First, try environment variables (for local development with emulators)
    const envConsumerKey = process.env.MPESA_CONSUMER_KEY;
    const envConsumerSecret = process.env.MPESA_CONSUMER_SECRET;
    const envPasskey = process.env.MPESA_PASSKEY;
    const envShortcode = process.env.MPESA_SHORTCODE;
    const envBaseUrl = process.env.MPESA_BASE_URL;
    if (envConsumerKey && envConsumerSecret && envPasskey && envShortcode) {
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
    }
    catch (error) {
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
 * Generate password for STK Push (Base64 encoded: Shortcode + Passkey + Timestamp)
 */
function generatePassword(shortcode, passkey) {
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
function getCallbackUrl() {
    var _a;
    // Check for ngrok URL in environment variable (for local development)
    const ngrokUrl = process.env.NGROK_URL;
    if (ngrokUrl) {
        // Remove trailing slash if present
        const cleanUrl = ngrokUrl.replace(/\/$/, '');
        return `${cleanUrl}/mpesaCallback`;
    }
    // Production: Use Firebase Cloud Functions URL
    const projectId = process.env.GCLOUD_PROJECT || ((_a = functions.config().project) === null || _a === void 0 ? void 0 : _a.id);
    const region = process.env.FUNCTION_REGION || "us-central1";
    // Construct callback URL
    // Format: https://[region]-[project-id].cloudfunctions.net/mpesaCallback
    return `https://${region}-${projectId}.cloudfunctions.net/mpesaCallback`;
}
/**
 * Initiate STK Push payment request
 */
async function initiateSTKPush(phoneNumber, amount, orderId) {
    var _a, _b;
    try {
        const config = getMpesaConfig();
        const accessToken = await (0, auth_1.getAccessToken)();
        const timestamp = new Date()
            .toISOString()
            .replace(/[^0-9]/g, "")
            .slice(0, -3); // Format: YYYYMMDDHHmmss
        const password = generatePassword(config.shortcode, config.passkey);
        const callbackUrl = getCallbackUrl();
        const stkPushRequest = {
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
        const response = await axios_1.default.post(stkPushUrl, stkPushRequest, {
            headers: {
                Authorization: `Bearer ${accessToken}`,
                "Content-Type": "application/json",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
                "Accept": "application/json",
            },
            timeout: 30000, // 30 second timeout
            validateStatus: function (status) {
                return status < 500; // Don't throw on 4xx errors, we'll handle them
            },
        });
        if (response.data.ResponseCode !== "0") {
            throw new Error(`STK Push failed: ${response.data.ResponseDescription}`);
        }
        functions.logger.info("STK Push initiated successfully", {
            CheckoutRequestID: response.data.CheckoutRequestID,
            MerchantRequestID: response.data.MerchantRequestID,
        });
        return response.data;
    }
    catch (error) {
        functions.logger.error("Failed to initiate STK Push", error);
        if (axios_1.default.isAxiosError(error)) {
            throw new Error(`M-Pesa API error: ${((_b = (_a = error.response) === null || _a === void 0 ? void 0 : _a.data) === null || _b === void 0 ? void 0 : _b.errorMessage) || error.message}`);
        }
        throw error;
    }
}
//# sourceMappingURL=stkPush.js.map