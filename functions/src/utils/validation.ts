/**
 * Input Validation Utilities
 */

/**
 * Validate and format phone number to M-Pesa format (254XXXXXXXXX)
 */
export function validateAndFormatPhoneNumber(phoneNumber: string): string {
  // Remove all non-digit characters
  const digitsOnly = phoneNumber.replace(/\D/g, "");

  // Handle different formats
  if (digitsOnly.startsWith("254")) {
    // Already in correct format
    if (digitsOnly.length === 12) {
      return digitsOnly;
    }
    throw new Error("Invalid phone number: must be 12 digits starting with 254");
  } else if (digitsOnly.startsWith("0")) {
    // Convert 07XXXXXXXX to 2547XXXXXXXX
    if (digitsOnly.length === 10) {
      return "254" + digitsOnly.substring(1);
    }
    throw new Error("Invalid phone number: must be 10 digits starting with 0");
  } else if (digitsOnly.length === 9) {
    // Convert 7XXXXXXXX to 2547XXXXXXXX
    return "254" + digitsOnly;
  } else {
    throw new Error(
      "Invalid phone number format. Use format: 254XXXXXXXXX or 07XXXXXXXX"
    );
  }
}

/**
 * Validate amount
 */
export function validateAmount(amount: number): void {
  if (amount <= 0) {
    throw new Error("Amount must be greater than 0");
  }
  if (amount < 1) {
    throw new Error("Minimum amount is KES 1");
  }
  if (amount > 70000) {
    throw new Error("Maximum amount is KES 70,000");
  }
}

/**
 * Validate order ID
 */
export function validateOrderId(orderId: string): void {
  if (!orderId || orderId.trim().length === 0) {
    throw new Error("Order ID is required");
  }
}
