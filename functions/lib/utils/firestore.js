"use strict";
/**
 * Firestore Helper Utilities
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
exports.updateOrderPaymentStatus = updateOrderPaymentStatus;
exports.getOrder = getOrder;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
// Initialize Firebase Admin if not already initialized
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
 * Update order payment status in Firestore
 */
async function updateOrderPaymentStatus(orderId, paymentStatus, transactionId, additionalData) {
    try {
        const orderRef = db.collection("orders").doc(orderId);
        const orderDoc = await orderRef.get();
        if (!orderDoc.exists) {
            throw new Error(`Order ${orderId} not found`);
        }
        const updates = Object.assign({ paymentStatus, updatedAt: getServerTimestamp() }, additionalData);
        if (transactionId) {
            // Validate transaction ID before storing
            const trimmedTransactionId = transactionId.trim();
            if (trimmedTransactionId.length > 0) {
                updates.mpesaTransactionId = trimmedTransactionId;
                functions.logger.info("Transaction ID will be stored", {
                    OrderID: orderId,
                    TransactionID: trimmedTransactionId,
                    TransactionIDLength: trimmedTransactionId.length,
                });
            }
            else {
                functions.logger.warn("Transaction ID is empty after trimming, not storing", {
                    OrderID: orderId,
                    OriginalTransactionID: transactionId,
                });
            }
        }
        else {
            functions.logger.warn("No transaction ID provided for order", {
                OrderID: orderId,
                PaymentStatus: paymentStatus,
            });
        }
        functions.logger.info("Updating order in Firestore", {
            OrderID: orderId,
            PaymentStatus: paymentStatus,
            HasTransactionID: !!updates.mpesaTransactionId,
            UpdateFields: Object.keys(updates),
        });
        await orderRef.update(updates);
        // Verify the update was successful
        const updatedDoc = await orderRef.get();
        const updatedData = updatedDoc.data();
        const storedTransactionId = updatedData === null || updatedData === void 0 ? void 0 : updatedData.mpesaTransactionId;
        functions.logger.info("Order updated successfully", {
            OrderID: orderId,
            PaymentStatus: paymentStatus,
            StoredTransactionID: storedTransactionId || "N/A",
            TransactionIDMatch: storedTransactionId === updates.mpesaTransactionId,
        });
    }
    catch (error) {
        functions.logger.error(`Failed to update order ${orderId} payment status`, error);
        throw error;
    }
}
/**
 * Get order by ID
 */
async function getOrder(orderId) {
    try {
        const orderRef = db.collection("orders").doc(orderId);
        const orderDoc = await orderRef.get();
        if (!orderDoc.exists) {
            throw new Error(`Order ${orderId} not found`);
        }
        return orderDoc;
    }
    catch (error) {
        functions.logger.error(`Failed to get order ${orderId}`, error);
        throw error;
    }
}
//# sourceMappingURL=firestore.js.map