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
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...additionalData,
    };

    if (transactionId) {
      updates.mpesaTransactionId = transactionId;
    }

    await orderRef.update(updates);
    functions.logger.info(`Updated order ${orderId} payment status to ${paymentStatus}`);
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
