/**
 * M-Pesa Callback Handler
 */

import * as functions from "firebase-functions";
import {MpesaCallbackBody} from "./types";
import {updateOrderPaymentStatus} from "../utils/firestore";

/**
 * Handle M-Pesa callback and update order status
 * Note: This function is kept for potential future use
 * The actual callback handling is done in index.ts mpesaCallback function
 */
export async function handleMpesaCallback(
  callbackBody: MpesaCallbackBody
): Promise<void> {
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
  } catch (error) {
    functions.logger.error("Error handling M-Pesa callback", error);
    throw error;
  }
}

/**
 * Update order based on CheckoutRequestID
 * This function queries orders to find the one with matching CheckoutRequestID
 */
export async function updateOrderByCheckoutRequestID(
  checkoutRequestID: string,
  paymentStatus: string,
  transactionId?: string
): Promise<void> {
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
      functions.logger.warn(
        `No order found with CheckoutRequestID: ${checkoutRequestID}`
      );
      return;
    }

    const orderDoc = ordersSnapshot.docs[0];
    const orderId = orderDoc.id;

    await updateOrderPaymentStatus(orderId, paymentStatus, transactionId);

    functions.logger.info(
      `Updated order ${orderId} with CheckoutRequestID ${checkoutRequestID}`
    );
  } catch (error) {
    functions.logger.error(
      `Failed to update order by CheckoutRequestID: ${checkoutRequestID}`,
      error
    );
    throw error;
  }
}
