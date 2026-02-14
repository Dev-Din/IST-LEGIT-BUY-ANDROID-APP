/**
 * Firebase Cloud Functions - Main Entry Point
 * M-Pesa Payment Integration
 */

// Load environment variables from .env file FIRST (before any imports that might need them)
import * as dotenv from "dotenv";
dotenv.config();

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {initiateSTKPush, getCallbackUrl} from "./mpesa/stkPush";
import {updateOrderByCheckoutRequestID} from "./mpesa/callback";
import {validateAndFormatPhoneNumber, validateAmount, validateOrderId} from "./utils/validation";
import {MpesaCallbackBody} from "./mpesa/types";

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
 * HTTP Callable Function: Initiate M-Pesa Payment
 * Called from Flutter app to start STK Push payment
 */
export const initiateMpesaPayment = functions.https.onCall(
  async (data, context) => {
    // #region agent log
    functions.logger.info("initiateMpesaPayment called", {
      userId: context.auth?.uid,
      phoneNumber: data?.phoneNumber,
      amount: data?.amount,
      orderId: data?.orderId,
      envConsumerSecret: process.env.MPESA_CONSUMER_SECRET ? process.env.MPESA_CONSUMER_SECRET.substring(0, 20) + "..." : "missing",
    });
    // #endregion

    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to initiate payment"
      );
    }

    try {
      // Validate input
      const {phoneNumber, amount, orderId} = data;

      if (!phoneNumber || !amount || !orderId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "phoneNumber, amount, and orderId are required"
        );
      }

      validateOrderId(orderId);
      validateAmount(amount);
      const formattedPhone = validateAndFormatPhoneNumber(phoneNumber);

      // Verify order exists and belongs to user
      const orderDoc = await db.collection("orders").doc(orderId).get();
      if (!orderDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Order not found"
        );
      }

      const orderData = orderDoc.data();
      if (orderData?.userId !== context.auth.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Order does not belong to user"
        );
      }

      // Initiate STK Push
      const callbackUrl = getCallbackUrl();
      const stkResponse = await initiateSTKPush(
        formattedPhone,
        amount,
        orderId
      );

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
    } catch (error: any) {
      // #region agent log
      const errorDetails = {
        message: error?.message,
        code: error?.code,
        stack: error?.stack,
        response: error?.response ? {
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
      
      throw new functions.https.HttpsError(
        "internal",
        error instanceof Error ? error.message : "Failed to initiate payment"
      );
    }
  }
);

/**
 * HTTP Function: M-Pesa Callback Webhook
 * Receives callbacks from M-Pesa API when payment is completed
 */
export const mpesaCallback = functions.https.onRequest(async (req, res) => {
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
    const callbackBody = req.body as MpesaCallbackBody;
    const stkCallback = callbackBody.Body?.stkCallback;

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
    let paymentStatus: string;
    let transactionId: string | undefined;

    if (resultCode === 0) {
      // Payment successful
      paymentStatus = "paid";
      
      // Extract transaction ID from callback metadata
      const metadata = stkCallback.CallbackMetadata?.Item;
      functions.logger.info("Extracting transaction ID from callback", {
        CheckoutRequestID: checkoutRequestID,
        hasMetadata: !!metadata,
        metadataLength: metadata?.length || 0,
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
        } else {
          functions.logger.warn("MpesaReceiptNumber not found in callback metadata", {
            CheckoutRequestID: checkoutRequestID,
            availableItems: metadata.map((item) => item.Name),
          });
        }
      } else {
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

      await updateOrderByCheckoutRequestID(
        checkoutRequestID,
        paymentStatus,
        transactionId
      );

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
    } else {
      // Payment failed
      paymentStatus = "failed";
      
      await updateOrderByCheckoutRequestID(
        checkoutRequestID,
        paymentStatus
      );
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
  } catch (error) {
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
export const paymentStatus = functions.https.onRequest(async (req, res) => {
  // Only accept GET requests
  if (req.method !== "GET") {
    res.status(405).json({ error: "Method Not Allowed" });
    return;
  }

  try {
    const checkoutRequestId = req.query.checkout_request_id as string;

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
    const paymentStatus = orderData.paymentStatus as string;
    const mpesaTransactionId = orderData.mpesaTransactionId as string | undefined;

    // Map Firestore paymentStatus to API response
    let status: "pending" | "completed" | "failed";
    let message: string;

    if (paymentStatus === "paid") {
      status = "completed";
      message = "Payment completed";
    } else if (paymentStatus === "failed") {
      status = "failed";
      message = "Payment failed";
    } else {
      // pending or processing
      status = "pending";
      message = "Payment pending";
    }

    const response: {
      status: "pending" | "completed" | "failed";
      message: string;
      mpesa_receipt?: string;
    } = {
      status,
      message,
    };

    if (mpesaTransactionId) {
      response.mpesa_receipt = mpesaTransactionId;
    }

    res.status(200).json(response);
  } catch (error) {
    functions.logger.error("Error getting payment status", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// --- Admin user management (CRUD) ---
const USERS_COLLECTION = "users";

async function requireAdminOrSuperAdmin(context: functions.https.CallableContext): Promise<void> {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Must be logged in");
  }
  const callerDoc = await db.collection(USERS_COLLECTION).doc(context.auth.uid).get();
  const callerRole = callerDoc.data()?.role as string | undefined;
  if (callerRole !== "admin" && callerRole !== "superadmin") {
    throw new functions.https.HttpsError("permission-denied", "Admin or Super Admin only");
  }
}

/**
 * Create a new user (Auth + Firestore). Callable by admin/superadmin only.
 * Data: { email, password, name, role } (role: customer | admin)
 */
export const createUserByAdmin = functions.https.onCall(async (data, context) => {
  await requireAdminOrSuperAdmin(context);

  const { email, password, name, role } = data || {};
  if (!email || typeof email !== "string" || !password || typeof password !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "email and password are required");
  }
  const safeName = typeof name === "string" ? name.trim() || email.split("@")[0] : email.split("@")[0];
  const safeRole = role === "admin" ? "admin" : "customer";

  try {
    const userRecord = await admin.auth().createUser({
      email: email.trim().toLowerCase(),
      password: String(password),
      displayName: safeName,
    });
    const uid = userRecord.uid;

    await db.collection(USERS_COLLECTION).doc(uid).set({
      email: email.trim().toLowerCase(),
      name: safeName,
      role: safeRole,
      createdAt: getServerTimestamp(),
    });

    return { success: true, uid, email: userRecord.email, name: safeName, role: safeRole };
  } catch (error: any) {
    functions.logger.error("createUserByAdmin error", error);
    if (error.code === "auth/email-already-exists") {
      throw new functions.https.HttpsError("already-exists", "Email already in use");
    }
    throw new functions.https.HttpsError("internal", error.message || "Failed to create user");
  }
});

/**
 * Delete a user (Auth + Firestore). Callable by admin/superadmin only.
 * Data: { userId }
 */
export const deleteUser = functions.https.onCall(async (data, context) => {
  await requireAdminOrSuperAdmin(context);

  const userId = data?.userId;
  if (!userId || typeof userId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "userId is required");
  }

  const targetDoc = await db.collection(USERS_COLLECTION).doc(userId).get();
  const targetRole = targetDoc.data()?.role as string | undefined;
  if (targetRole === "superadmin") {
    throw new functions.https.HttpsError("permission-denied", "Cannot delete super admin");
  }

  try {
    await admin.auth().deleteUser(userId);
    await db.collection(USERS_COLLECTION).doc(userId).delete();
    return { success: true };
  } catch (error: any) {
    functions.logger.error("deleteUser error", error);
    throw new functions.https.HttpsError("internal", error.message || "Failed to delete user");
  }
});
