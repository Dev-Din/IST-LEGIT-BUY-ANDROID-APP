"use strict";
/**
 * M-Pesa Callback Handler
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
exports.handleMpesaCallback = handleMpesaCallback;
exports.updateOrderByCheckoutRequestID = updateOrderByCheckoutRequestID;
const functions = __importStar(require("firebase-functions"));
const firestore_1 = require("../utils/firestore");
/**
 * Handle M-Pesa callback and update order status
 * Note: This function is kept for potential future use
 * The actual callback handling is done in index.ts mpesaCallback function
 */
async function handleMpesaCallback(callbackBody) {
    try {
        const stkCallback = callbackBody.Body.stkCallback;
        const resultCode = stkCallback.ResultCode;
        const resultDesc = stkCallback.ResultDesc;
        const checkoutRequestID = stkCallback.CheckoutRequestID;
        const merchantRequestID = stkCallback.MerchantRequestID;
        functions.logger.info("M-Pesa callback received", {
            ResultCode: resultCode,
            ResultDesc: resultDesc,
            CheckoutRequestID: checkoutRequestID,
            MerchantRequestID: merchantRequestID,
        });
        // Note: This function is kept for potential future use
        // The actual callback handling is done in index.ts mpesaCallback function
        // which uses updateOrderByCheckoutRequestID to update orders
        functions.logger.info("handleMpesaCallback called", {
            ResultCode: resultCode,
            CheckoutRequestID: checkoutRequestID,
        });
        return;
    }
    catch (error) {
        functions.logger.error("Error handling M-Pesa callback", error);
        throw error;
    }
}
/**
 * Update order based on CheckoutRequestID
 * This function queries orders to find the one with matching CheckoutRequestID
 */
async function updateOrderByCheckoutRequestID(checkoutRequestID, paymentStatus, transactionId) {
    try {
        const admin = require("firebase-admin");
        const db = admin.firestore();
        // Query orders to find one with matching CheckoutRequestID
        // We'll store CheckoutRequestID in the order document when initiating STK Push
        const ordersSnapshot = await db
            .collection("orders")
            .where("checkoutRequestID", "==", checkoutRequestID)
            .limit(1)
            .get();
        if (ordersSnapshot.empty) {
            functions.logger.warn(`No order found with CheckoutRequestID: ${checkoutRequestID}`);
            return;
        }
        const orderDoc = ordersSnapshot.docs[0];
        const orderId = orderDoc.id;
        await (0, firestore_1.updateOrderPaymentStatus)(orderId, paymentStatus, transactionId);
        functions.logger.info(`Updated order ${orderId} with CheckoutRequestID ${checkoutRequestID}`);
    }
    catch (error) {
        functions.logger.error(`Failed to update order by CheckoutRequestID: ${checkoutRequestID}`, error);
        throw error;
    }
}
//# sourceMappingURL=callback.js.map