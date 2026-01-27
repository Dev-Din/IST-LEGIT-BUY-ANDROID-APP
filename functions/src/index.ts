/**
 * Firebase Cloud Functions - Main Entry Point
 * M-Pesa Payment Integration
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {initiateSTKPush} from "./mpesa/stkPush";
import {updateOrderByCheckoutRequestID} from "./mpesa/callback";
import {validateAndFormatPhoneNumber, validateAmount, validateOrderId} from "./utils/validation";
import {MpesaCallbackBody} from "./mpesa/types";

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * HTTP Callable Function: Initiate M-Pesa Payment
 * Called from Flutter app to start STK Push payment
 */
export const initiateMpesaPayment = functions.https.onCall(
  async (data, context) => {
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
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      functions.logger.info("STK Push initiated", {
        orderId,
        checkoutRequestID: stkResponse.CheckoutRequestID,
      });

      // Return response to Flutter app
      return {
        success: true,
        checkoutRequestID: stkResponse.CheckoutRequestID,
        merchantRequestID: stkResponse.MerchantRequestID,
        customerMessage: stkResponse.CustomerMessage,
      };
    } catch (error) {
      functions.logger.error("Error initiating M-Pesa payment", error);
      
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
  // Only accept POST requests
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
      if (metadata) {
        const receiptItem = metadata.find((item) => item.Name === "MpesaReceiptNumber");
        if (receiptItem) {
          transactionId = String(receiptItem.Value);
        }
      }

      // Update order status
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
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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
