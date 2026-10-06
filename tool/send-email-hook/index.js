// Supabase "Send Email" auth hook for I Want, run on our own Node.js server.
//
// Supabase calls this endpoint (instead of its own mailer) whenever it needs to
// email a user: login codes, signup confirmation, email change. We verify the
// call is really from Supabase, then hand the email to our own sender.
//
// Env:
//   SEND_EMAIL_HOOK_SECRET  the "v1,whsec_..." secret Supabase shows for the hook
//   PORT                    default 8787
//
// Plug the existing mailer into sendMail() below. No npm packages needed.
import { createHmac, timingSafeEqual } from 'node:crypto';
import { createServer } from 'node:http';

async function sendMail({ to, subject, html, text }) {
  // TODO: call our existing Node.js email sender here.
  throw new Error(`sendMail not wired yet (to ${to}, subject "${subject}")`);
}

const SECRET = (process.env.SEND_EMAIL_HOOK_SECRET ?? '').replace(/^v1,whsec_/, '');
const MAX_SKEW_SECONDS = 5 * 60;

// Standard Webhooks signature check (https://www.standardwebhooks.com).
function verify(headers, body) {
  const id = headers['webhook-id'];
  const timestamp = headers['webhook-timestamp'];
  const signatures = headers['webhook-signature'];
  if (!SECRET || !id || !timestamp || !signatures) return false;
  if (Math.abs(Date.now() / 1000 - Number(timestamp)) > MAX_SKEW_SECONDS) return false;
  const expected = createHmac('sha256', Buffer.from(SECRET, 'base64'))
    .update(`${id}.${timestamp}.${body}`)
    .digest();
  return signatures.split(' ').some((entry) => {
    const [version, sig] = entry.split(',');
    if (version !== 'v1' || !sig) return false;
    const given = Buffer.from(sig, 'base64');
    return given.length === expected.length && timingSafeEqual(given, expected);
  });
}

const SUBJECTS = {
  magiclink: 'Your I Want sign-in code',
  signup: 'Your I Want sign-in code',
  email_change: 'Confirm your new email for I Want',
  recovery: 'Your I Want sign-in code',
  reauthentication: 'Your I Want confirmation code',
};

function codeEmail(code) {
  const text = `Your I Want code is ${code}\n\nEnter it in the I Want app. Do not share this code with anyone. If you didn't ask for it, you can ignore this email.`;
  const html = `<!doctype html><html><body style="margin:0;padding:24px;background:#f6f6f6;font-family:Arial,Helvetica,sans-serif;color:#1f1f1f;">
<div style="max-width:440px;margin:0 auto;background:#ffffff;border-radius:12px;padding:32px;">
<p style="margin:0 0 16px;font-size:20px;font-weight:700;">I Want</p>
<p style="margin:0 0 16px;font-size:16px;">Your code is:</p>
<p style="margin:0 0 24px;font-size:32px;font-weight:700;letter-spacing:8px;">${code}</p>
<p style="margin:0 0 8px;font-size:14px;color:#555555;">Enter it in the I Want app. Do not share this code with anyone.</p>
<p style="margin:0;font-size:14px;color:#555555;">If you didn't ask for it, you can ignore this email.</p>
</div></body></html>`;
  return { text, html };
}

async function handle(payload) {
  const { user, email_data: data } = payload;
  const type = data.email_action_type;
  // An email change sends a code to the new address (token_new) as well as the old one.
  const sends = [{ to: user.email, code: data.token }];
  if (type === 'email_change' && data.token_new && user.new_email) {
    sends.push({ to: user.new_email, code: data.token_new });
  }
  for (const { to, code } of sends) {
    if (!to || !code) continue;
    await sendMail({ to, subject: SUBJECTS[type] ?? 'Your I Want code', ...codeEmail(code) });
  }
}

function reply(res, status, body) {
  res.writeHead(status, { 'content-type': 'application/json' });
  res.end(JSON.stringify(body));
}

createServer(async (req, res) => {
  if (req.method !== 'POST') return reply(res, 405, { error: { http_code: 405, message: 'POST only' } });
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const body = Buffer.concat(chunks).toString('utf8');
  if (!verify(req.headers, body)) return reply(res, 401, { error: { http_code: 401, message: 'bad signature' } });
  try {
    await handle(JSON.parse(body));
    reply(res, 200, {});
  } catch (err) {
    console.error('send-email-hook failed:', err);
    reply(res, 500, { error: { http_code: 500, message: 'could not send email' } });
  }
}).listen(Number(process.env.PORT ?? 8787), () => {
  console.log(`send-email-hook listening on ${process.env.PORT ?? 8787}`);
});
