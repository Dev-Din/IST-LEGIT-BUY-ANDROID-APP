/**
 * Firestore Helper Utilities
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

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
  } catch (error) {
    functions.logger.warn("FieldValue.serverTimestamp not available");
  }
  // Fallback: use current timestamp as Date, Firestore will convert it
  try {
    if (admin.firestore && admin.firestore.Timestamp && admin.firestore.Timestamp.now) {
      return admin.firestore.Timestamp.now();
    }
  } catch (error) {
    functions.logger.warn("Timestamp.now() not available, using Date");
  }
  // Final fallback: use JavaScript Date
  return new Date();
}

/**
 * Update order payment status in Firestore
 */
export async function updateOrderPaymentStatus(
  orderId: string,
  paymentStatus: string,
  transactionId?: string,
  additionalData?: Record<string, unknown>
): Promise<void> {
  try {
    const orderRef = db.collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();

    if (!orderDoc.exists) {
      throw new Error(`Order ${orderId} not found`);
    }

    const updates: Record<string, unknown> = {
      paymentStatus,
      updatedAt: getServerTimestamp(),
      ...additionalData,
    };

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
      } else {
        functions.logger.warn("Transaction ID is empty after trimming, not storing", {
          OrderID: orderId,
          OriginalTransactionID: transactionId,
        });
      }
    } else {
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
    const storedTransactionId = updatedData?.mpesaTransactionId;

    functions.logger.info("Order updated successfully", {
      OrderID: orderId,
      PaymentStatus: paymentStatus,
      StoredTransactionID: storedTransactionId || "N/A",
      TransactionIDMatch: storedTransactionId === updates.mpesaTransactionId,
    });
  } catch (error) {
    functions.logger.error(`Failed to update order ${orderId} payment status`, error);
    throw error;
  }
}

/**
 * Get order by ID
 */
export async function getOrder(orderId: string): Promise<admin.firestore.DocumentSnapshot> {
  try {
    const orderRef = db.collection("orders").doc(orderId);
    const orderDoc = await orderRef.get();

    if (!orderDoc.exists) {
      throw new Error(`Order ${orderId} not found`);
    }

    return orderDoc;
  } catch (error) {
    functions.logger.error(`Failed to get order ${orderId}`, error);
    throw error;
  }
}
