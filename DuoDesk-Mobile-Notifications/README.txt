DuoDesk Mobile Notifications Update

Files:
- index.html: updated DuoDesk app with mobile/browser notifications and deadline reminders
- sw.js: service worker used to display notifications and handle notification taps
- notifications-migration.sql: notification table/policies migration from the previous release

Deploy all files to the same root directory on Vercel. Keep sw.js at /sw.js (same origin as index.html).

Then:
1. Open the deployed HTTPS app on the phone in Chrome.
2. Sign in.
3. Open Notifications and tap Enable mobile alerts.
4. Allow notifications in the Android/browser permission prompt.
5. Test with a message from the other account or a work deadline.

Important limitation: this version can show system notifications while the app/browser is running and it checks reminders while the app is open. It does not deliver reliable push notifications when the app is fully closed or the phone is offline. That requires a push subscription and a server-side push sender (for example, a Supabase Edge Function with VAPID keys).
