"use strict";
/**
 * Firebase Cloud Functions - Main Entry Point
 * M-Pesa Payment Integration
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.paymentStatus = exports.mpesaCallback = exports.initiateMpesaPayment = void 0;
// Load environment variables from .env file FIRST (before any imports that might need them)
const dotenv = __importStar(require("dotenv"));
dotenv.config();
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const stkPush_1 = require("./mpesa/stkPush");
const callback_1 = require("./mpesa/callback");
const validation_1 = require("./utils/validation");
// Initialize Firebase Admin
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
// Helper function to get serverTimestamp - handles emulator compatibility
function getServerTimestamp() {
    try {
        if (admin.firestore && admin.firestore.FieldValue && admin.firestore.FieldValue.serverTimestamp) {
            return admin.firestore.FieldValue.serverTimestamp();
        }
    }
    catch (error) {
        functions.logger.warn("FieldValue.serverTimestamp not available");
    }
    // Fallback: use current timestamp as Date, Firestore will convert it
    try {
        if (admin.firestore && admin.firestore.Timestamp && admin.firestore.Timestamp.now) {
            return admin.firestore.Timestamp.now();
        }
    }
    catch (error) {
        functions.logger.warn("Timestamp.now() not available, using Date");
    }
    // Final fallback: use JavaScript Date
    return new Date();
}
/**
 * HTTP Callable Function: Initiate M-Pesa Payment
 * Called from Flutter app to start STK Push payment
 */
exports.initiateMpesaPayment = functions.https.onCall(async (data, context) => {
    var _a;
    // #region agent log
    functions.logger.info("initiateMpesaPayment called", {
        userId: (_a = context.auth) === null || _a === void 0 ? void 0 : _a.uid,
        phoneNumber: data === null || data === void 0 ? void 0 : data.phoneNumber,
        amount: data === null || data === void 0 ? void 0 : data.amount,
        orderId: data === null || data === void 0 ? void 0 : data.orderId,
        envConsumerSecret: process.env.MPESA_CONSUMER_SECRET ? process.env.MPESA_CONSUMER_SECRET.substring(0, 20) + "..." : "missing",
    });
    // #endregion
    // Verify user is authenticated
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated to initiate payment");
    }
    try {
        // Validate input
        const { phoneNumber, amount, orderId } = data;
        if (!phoneNumber || !amount || !orderId) {
            throw new functions.https.HttpsError("invalid-argument", "phoneNumber, amount, and orderId are required");
        }
        (0, validation_1.validateOrderId)(orderId);
        (0, validation_1.validateAmount)(amount);
        const formattedPhone = (0, validation_1.validateAndFormatPhoneNumber)(phoneNumber);
        // Verify order exists and belongs to user
        const orderDoc = await db.collection("orders").doc(orderId).get();
        if (!orderDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Order not found");
        }
        const orderData = orderDoc.data();
        if ((orderData === null || orderData === void 0 ? void 0 : orderData.userId) !== context.auth.uid) {
            throw new functions.https.HttpsError("permission-denied", "Order does not belong to user");
        }
        // Initiate STK Push
        const callbackUrl = (0, stkPush_1.getCallbackUrl)();
        const stkResponse = await (0, stkPush_1.initiateSTKPush)(formattedPhone, amount, orderId);
        // Store CheckoutRequestID in order for callback matching
        await db.collection("orders").doc(orderId).update({
            checkoutRequestID: stkResponse.CheckoutRequestID,
            merchantRequestID: stkResponse.MerchantRequestID,
            paymentStatus: "processing",
            updatedAt: getServerTimestamp(),
        });
        functions.logger.info("STK Push initiated", {
            orderId,
            checkoutRequestID: stkResponse.CheckoutRequestID,
            callbackUrl: callbackUrl,
        });
        // Return response to Flutter app
        return {
            success: true,
            checkoutRequestID: stkResponse.CheckoutRequestID,
            merchantRequestID: stkResponse.MerchantRequestID,
            customerMessage: stkResponse.CustomerMessage,
        };
    }
    catch (error) {
        // #region agent log
        const errorDetails = {
            message: error === null || error === void 0 ? void 0 : error.message,
            code: error === null || error === void 0 ? void 0 : error.code,
            stack: error === null || error === void 0 ? void 0 : error.stack,
            response: (error === null || error === void 0 ? void 0 : error.response) ? {
                status: error.response.status,
                statusText: error.response.statusText,
                data: error.response.data,
            } : undefined,
        };
        functions.logger.error("Error initiating M-Pesa payment - detailed", JSON.stringify(errorDetails, null, 2));
        // #endregion
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError("internal", error instanceof Error ? error.message : "Failed to initiate payment");
    }
});
/**
 * HTTP Function: M-Pesa Callback Webhook
 * Receives callbacks from M-Pesa API when payment is completed
 */
exports.mpesaCallback = functions.https.onRequest(async (req, res) => {
    var _a, _b;
    // Handle GET requests for health check / manual verification
    if (req.method === "GET") {
        res.status(200).json({
            ok: true,
            message: "Callback URL is reachable",
            endpoint: "mpesaCallback",
        });
        return;
    }
    // Only accept POST requests for actual callbacks
    if (req.method !== "POST") {
        res.status(405).send("Method Not Allowed");
        return;
    }
    try {
        const callbackBody = req.body;
        const stkCallback = (_a = callbackBody.Body) === null || _a === void 0 ? void 0 : _a.stkCallback;
        if (!stkCallback) {
            functions.logger.error("Invalid callback body structure", req.body);
            res.status(400).send("Invalid callback body");
            return;
        }
        const resultCode = stkCallback.ResultCode;
        const checkoutRequestID = stkCallback.CheckoutRequestID;
        functions.logger.info("M-Pesa callback received", {
            ResultCode: resultCode,
            CheckoutRequestID: checkoutRequestID,
        });
        // Determine payment status based on result code
        let paymentStatus;
        let transactionId;
        if (resultCode === 0) {
            // Payment successful
            paymentStatus = "paid";
            // Extract transaction ID from callback metadata
            const metadata = (_b = stkCallback.CallbackMetadata) === null || _b === void 0 ? void 0 : _b.Item;
            functions.logger.info("Extracting transaction ID from callback", {
                CheckoutRequestID: checkoutRequestID,
                hasMetadata: !!metadata,
                metadataLength: (metadata === null || metadata === void 0 ? void 0 : metadata.length) || 0,
            });
            if (metadata) {
                const receiptItem = metadata.find((item) => item.Name === "MpesaReceiptNumber");
                if (receiptItem) {
                    transactionId = String(receiptItem.Value);
                    functions.logger.info("Transaction ID extracted successfully", {
                        CheckoutRequestID: checkoutRequestID,
                        TransactionID: transactionId,
                        TransactionIDLength: transactionId.length,
                    });
                }
                else {
                    functions.logger.warn("MpesaReceiptNumber not found in callback metadata", {
                        CheckoutRequestID: checkoutRequestID,
                        availableItems: metadata.map((item) => item.Name),
                    });
                }
            }
            else {
                functions.logger.warn("Callback metadata is missing", {
                    CheckoutRequestID: checkoutRequestID,
                });
            }
            // Validate transaction ID before storing
            if (!transactionId || transactionId.trim().length === 0) {
                functions.logger.error("Transaction ID is empty or invalid", {
                    CheckoutRequestID: checkoutRequestID,
                    TransactionID: transactionId,
                });
                // Continue with payment status update even if transaction ID is missing
                // Admin can manually verify the payment
            }
            // Update order status
            functions.logger.info("Updating order with payment status and transaction ID", {
                CheckoutRequestID: checkoutRequestID,
                PaymentStatus: paymentStatus,
                HasTransactionID: !!transactionId,
                TransactionID: transactionId || "N/A",
            });
            await (0, callback_1.updateOrderByCheckoutRequestID)(checkoutRequestID, paymentStatus, transactionId);
            // Also update order status to "processing" (admin can change to "completed" later)
            const ordersSnapshot = await db
                .collection("orders")
                .where("checkoutRequestID", "==", checkoutRequestID)
                .limit(1)
                .get();
            if (!ordersSnapshot.empty) {
                const orderDoc = ordersSnapshot.docs[0];
                await orderDoc.ref.update({
                    status: "processing",
                    updatedAt: getServerTimestamp(),
                });
            }
        }
        else {
            // Payment failed
            paymentStatus = "failed";
            await (0, callback_1.updateOrderByCheckoutRequestID)(checkoutRequestID, paymentStatus);
        }
        // Always return 200 OK to M-Pesa (they will retry if we don't)
        res.status(200).json({
            ResultCode: 0,
            ResultDesc: "Callback processed successfully",
        });
        functions.logger.info("M-Pesa callback processed", {
            CheckoutRequestID: checkoutRequestID,
            PaymentStatus: paymentStatus,
        });
    }
    catch (error) {
        functions.logger.error("Error processing M-Pesa callback", error);
        // Still return 200 to prevent M-Pesa from retrying
        // Log the error for manual investigation
        res.status(200).json({
            ResultCode: 0,
            ResultDesc: "Callback received (error logged)",
        });
    }
});
/**
 * HTTP Function: Get payment status by checkout request ID
 * Returns payment status from Firestore for polling
 */
exports.paymentStatus = functions.https.onRequest(async (req, res) => {
    // Only accept GET requests
    if (req.method !== "GET") {
        res.status(405).json({ error: "Method Not Allowed" });
        return;
    }
    try {
        const checkoutRequestId = req.query.checkout_request_id;
        if (!checkoutRequestId) {
            res.status(400).json({ error: "checkout_request_id is required" });
            return;
        }
        // Query Firestore for order with matching checkoutRequestID
        const ordersSnapshot = await db
            .collection("orders")
            .where("checkoutRequestID", "==", checkoutRequestId)
            .limit(1)
            .get();
        if (ordersSnapshot.empty) {
            res.status(404).json({ error: "Payment not found" });
            return;
        }
        const orderDoc = ordersSnapshot.docs[0];
        const orderData = orderDoc.data();
        const paymentStatus = orderData.paymentStatus;
        const mpesaTransactionId = orderData.mpesaTransactionId;
        // Map Firestore paymentStatus to API response
        let status;
        let message;
        if (paymentStatus === "paid") {
            status = "completed";
            message = "Payment completed";
        }
        else if (paymentStatus === "failed") {
            status = "failed";
            message = "Payment failed";
        }
        else {
            // pending or processing
            status = "pending";
            message = "Payment pending";
        }
        const response = {
            status,
            message,
        };
        if (mpesaTransactionId) {
            response.mpesa_receipt = mpesaTransactionId;
        }
        res.status(200).json(response);
    }
    catch (error) {
        functions.logger.error("Error getting payment status", error);
        res.status(500).json({ error: "Internal server error" });
    }
});
//# sourceMappingURL=index.js.map