# Local Development Setup Guide

This guide explains how to set up and run the Firebase Emulators with ngrok for local M-Pesa sandbox testing.

## Prerequisites

1. **Firebase CLI** - Install if not already installed:
   ```bash
   npm install -g firebase-tools
   ```

2. **ngrok** - Install ngrok for exposing local Functions emulator:
   ```bash
   # On Linux
   curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
   echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
   sudo apt update && sudo apt install ngrok
   
   # Or download from https://ngrok.com/download
   ```

3. **ngrok Account** - Sign up for a free account:
   - Go to https://dashboard.ngrok.com/signup
   - Get your authtoken from the dashboard
   - Configure ngrok:
     ```bash
     ngrok config add-authtoken YOUR_AUTH_TOKEN
     ```

4. **Node.js and npm** - Required for Firebase Functions (Node.js 18)

5. **Flutter SDK** - Required for running the Flutter app

## Setup Steps

### Step 1: Install Function Dependencies

Navigate to the functions directory and install dependencies:

```bash
cd functions
npm install
cd ..
```

### Step 2: Configure ngrok URL

1. Start ngrok tunnel (in a separate terminal):
   ```bash
   ngrok http 5001
   ```

2. Copy the HTTPS URL shown (e.g., `https://abc123.ngrok.io`)

3. Update `functions/.env` file:
   ```bash
   # Open functions/.env and set:
   NGROK_URL=https://abc123.ngrok.io
   ```
   **Note:** Remove any trailing slashes from the URL.

### Step 3: Start Firebase Emulators

In the project root directory:

```bash
firebase emulators:start
```

This will start:
- Functions emulator on port 5001
- Firestore emulator on port 8080
- Auth emulator on port 9099
- Emulator UI on port 4000

You can access the Emulator UI at: http://localhost:4000

**Important:** Keep this terminal running while developing.

### Step 4: Run Flutter App

In a new terminal, run the Flutter app:

```bash
flutter run
```

The app will automatically connect to local emulators when running in debug mode.

## Development Workflow

### Starting a Development Session

1. **Terminal 1** - Start Firebase Emulators:
   ```bash
   firebase emulators:start
   ```

2. **Terminal 2** - Start ngrok tunnel:
   ```bash
   ngrok http 5001
   ```
   Copy the HTTPS URL shown.

3. **Update ngrok URL** (if it changed):
   - Edit `functions/.env`
   - Set `NGROK_URL` to the new ngrok HTTPS URL
   - Restart Firebase Emulators (Ctrl+C and restart)

4. **Terminal 3** - Run Flutter app:
   ```bash
   flutter run
   ```

### Testing M-Pesa Payments

1. Use the Flutter app to create an order
2. Enter a test phone number (M-Pesa sandbox format: 254712345678)
3. Initiate payment - STK Push will be sent to M-Pesa sandbox
4. M-Pesa callback will reach your local Functions emulator via ngrok
5. Check Emulator UI at http://localhost:4000 to see:
   - Function invocations
   - Firestore data updates
   - Auth events

## Port Configuration

- **Functions Emulator**: `localhost:5001`
- **Firestore Emulator**: `localhost:8080`
- **Auth Emulator**: `localhost:9099`
- **Emulator UI**: `localhost:4000`
- **ngrok**: Forwards to port 5001 (Functions emulator)

## Important Notes

### ngrok URL Changes

- Free ngrok accounts get a new URL each time you restart ngrok
- If you restart ngrok, you must:
  1. Update `functions/.env` with the new URL
  2. Restart Firebase Emulators for the change to take effect

### Debug Mode Only

- Emulator connections only work in **debug mode** (`kDebugMode = true`)
- Production/release builds will connect to Firebase production services
- This is intentional for security and performance

### M-Pesa Sandbox Credentials

- The app uses M-Pesa sandbox credentials configured in `functions/src/mpesa/auth.ts`
- These are safe for local testing
- Never commit production credentials to version control

## Troubleshooting

### Emulators Won't Start

**Error:** `Port already in use`
- **Solution:** Stop any process using ports 5001, 8080, 9099, or 4000
- Find and kill the process:
  ```bash
  lsof -i :5001  # Find process using port 5001
  kill -9 <PID>  # Kill the process
  ```

### Flutter App Can't Connect to Emulators

**Error:** `Connection refused` or `Network error`
- **Solution:** 
  1. Verify emulators are running: `firebase emulators:start`
  2. Check you're running in debug mode (not release)
  3. Verify ports match configuration

### M-Pesa Callbacks Not Received

**Issue:** Payment initiated but callback never arrives
- **Solution:**
  1. Verify ngrok is running: `ngrok http 5001`
  2. Check `functions/.env` has correct `NGROK_URL`
  3. Restart Firebase Emulators after updating `.env`
  4. Check ngrok web interface: http://localhost:4040 (shows requests)
  5. Verify callback URL in M-Pesa request logs matches ngrok URL

### Environment Variables Not Loading

**Issue:** `NGROK_URL` not found
- **Solution:**
  1. Ensure `functions/.env` file exists
  2. Verify `dotenv` package is installed: `cd functions && npm install`
  3. Check `.env` file format (no spaces around `=`)
  4. Restart emulators after creating/updating `.env`

### TypeScript Compilation Errors

**Error:** Type errors in functions
- **Solution:**
  ```bash
  cd functions
  npm run build
  ```
  Check for TypeScript errors and fix them before starting emulators.

## Benefits of Local Development

- ✅ **No billing required** - All services run locally
- ✅ **No Cloud Build API needed** - No deployment required
- ✅ **No Artifact Registry API needed** - No Docker images
- ✅ **Fast iteration** - Instant code changes without deployment
- ✅ **Easy testing** - Reset data anytime
- ✅ **Real M-Pesa integration** - Test with actual sandbox API
- ✅ **Full debugging** - See all logs and data in Emulator UI

## Production Deployment

When ready to deploy to production:

1. Remove emulator connections from code (or they're already debug-only)
2. Deploy Firebase Functions:
   ```bash
   firebase deploy --only functions
   ```
3. Update M-Pesa callback URL in production (will use Firebase Cloud Functions URL automatically)
4. Build and deploy Flutter app for production

## Additional Resources

- [Firebase Emulators Documentation](https://firebase.google.com/docs/emulator-suite)
- [ngrok Documentation](https://ngrok.com/docs)
- [M-Pesa Sandbox Documentation](https://developer.safaricom.co.ke/docs)
