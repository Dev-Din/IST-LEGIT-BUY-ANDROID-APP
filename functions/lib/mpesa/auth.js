"use strict";
/**
 * M-Pesa OAuth Token Generation
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
exports.getAccessToken = getAccessToken;
const dotenv = __importStar(require("dotenv"));
const axios_1 = __importDefault(require("axios"));
const functions = __importStar(require("firebase-functions"));
// Load environment variables from .env file
dotenv.config();
let cachedToken = null;
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
 * Generate OAuth access token for M-Pesa API
 * Caches token until expiration to avoid unnecessary API calls
 */
async function getAccessToken() {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l;
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
        consumerKeyLength: ((_a = config.consumerKey) === null || _a === void 0 ? void 0 : _a.length) || 0,
    });
    // #endregion
    try {
        const response = await axios_1.default.get(authUrl, {
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
            tokenLength: (accessToken === null || accessToken === void 0 ? void 0 : accessToken.length) || 0,
            expiresIn: expiresIn,
        });
        // #endregion
        // Cache the token
        cachedToken = {
            token: accessToken,
            expiresAt: Date.now() + expiresIn,
        };
        return accessToken;
    }
    catch (error) {
        // #region agent log
        const errorDetails = {
            message: (error === null || error === void 0 ? void 0 : error.message) || "Unknown error",
            code: error === null || error === void 0 ? void 0 : error.code,
            status: (_b = error === null || error === void 0 ? void 0 : error.response) === null || _b === void 0 ? void 0 : _b.status,
            statusText: (_c = error === null || error === void 0 ? void 0 : error.response) === null || _c === void 0 ? void 0 : _c.statusText,
            data: (_d = error === null || error === void 0 ? void 0 : error.response) === null || _d === void 0 ? void 0 : _d.data,
            headers: (_e = error === null || error === void 0 ? void 0 : error.response) === null || _e === void 0 ? void 0 : _e.headers,
            config: {
                url: (_f = error === null || error === void 0 ? void 0 : error.config) === null || _f === void 0 ? void 0 : _f.url,
                method: (_g = error === null || error === void 0 ? void 0 : error.config) === null || _g === void 0 ? void 0 : _g.method,
                auth: ((_h = error === null || error === void 0 ? void 0 : error.config) === null || _h === void 0 ? void 0 : _h.auth) ? "Present" : "Missing",
            },
        };
        functions.logger.error("Failed to get M-Pesa access token - detailed error", JSON.stringify(errorDetails, null, 2));
        // Log the raw response if available
        if ((_j = error === null || error === void 0 ? void 0 : error.response) === null || _j === void 0 ? void 0 : _j.data) {
            functions.logger.error("M-Pesa API Error Response Body", typeof error.response.data === 'string'
                ? error.response.data
                : JSON.stringify(error.response.data, null, 2));
        }
        // #endregion
        // Provide more helpful error message
        if (((_k = error === null || error === void 0 ? void 0 : error.response) === null || _k === void 0 ? void 0 : _k.status) === 400) {
            const errorMsg = ((_l = error === null || error === void 0 ? void 0 : error.response) === null || _l === void 0 ? void 0 : _l.data)
                ? (typeof error.response.data === 'string' ? error.response.data : JSON.stringify(error.response.data))
                : "Bad Request - Check credentials and API endpoint";
            throw new Error(`M-Pesa API returned 400 Bad Request: ${errorMsg}`);
        }
        throw new Error(`Failed to authenticate with M-Pesa API: ${(error === null || error === void 0 ? void 0 : error.message) || "Unknown error"}`);
    }
}
//# sourceMappingURL=auth.js.map