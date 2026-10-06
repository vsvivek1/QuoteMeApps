# Send Email hook (own Node.js mailer)

Supabase Auth calls this endpoint instead of its built-in mailer, so login codes
go out through our own Node.js email system. No npm packages are needed.

1. Wire our existing mailer into `sendMail()` in `index.js`.
2. Run it on our server behind HTTPS (`npm start`, Node 18+), for example at
   `https://<our-domain>/auth/send-email`.
3. Supabase dashboard -> Authentication -> Auth Hooks -> Send Email hook -> type HTTPS,
   paste that URL, click "Generate secret", save.
4. Put that secret (`v1,whsec_...`) in the server env as `SEND_EMAIL_HOOK_SECRET`.

Once the hook is on, every auth email (login codes, signup, email change) goes
through it. The app uses 6-digit codes, so each email carries `email_data.token`.
