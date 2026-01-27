# Firebase Cloud Functions - M-Pesa Payment Integration

This directory contains Firebase Cloud Functions for handling M-Pesa STK Push payments.

## Setup

1. Install dependencies:
```bash
cd functions
npm install
```

2. Set M-Pesa credentials:
```bash
firebase functions:config:set \
  mpesa.consumer_key="yVcigqegMbip51XGxKZNm5JYf8eVTrFSuQF9rLMi657wjPDP" \
  mpesa.consumer_secret="u7GKHXpo55Apq6sfbyXj5D9R3YclLxy7OA5jWhZ9PqLfMPB2pDAWFqob1ExFyFC2" \
  mpesa.passkey="bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919" \
  mpesa.shortcode="174379" \
  mpesa.base_url="https://sandbox.safaricom.co.ke"
```

3. Build TypeScript:
```bash
npm run build
```

4. Deploy functions:
```bash
npm run deploy
```

## Functions

### `initiateMpesaPayment`
HTTP Callable function that initiates M-Pesa STK Push payment.

**Input:**
- `phoneNumber`: string (format: 254XXXXXXXXX or 07XXXXXXXX)
- `amount`: number
- `orderId`: string

**Returns:**
- `success`: boolean
- `checkoutRequestID`: string
- `merchantRequestID`: string
- `customerMessage`: string

### `mpesaCallback`
HTTP function (webhook) that receives callbacks from M-Pesa API.

**URL Format:** `https://[region]-[project-id].cloudfunctions.net/mpesaCallback`

This URL is automatically used as the callback URL in STK Push requests.

## Development

- Build: `npm run build`
- Serve locally: `npm run serve`
- View logs: `npm run logs`

## Notes

- Uses M-Pesa Sandbox for testing
- Callback URL is automatically generated after deployment
- All M-Pesa credentials are stored in Firebase Functions config (not in code)
