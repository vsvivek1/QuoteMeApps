/**
 * Progressive form submit: JSON POST to the Supabase Edge Function (FORMS_ENDPOINT).
 * The function must verify the Turnstile token server-side, check the honeypot,
 * rate-limit per IP, and store consent text + timestamp. Nothing here is secret.
 */
declare global {
  interface Window {
    turnstile?: { reset: (el?: Element | string) => void };
  }
}

/** Message from the form's data-msg-* attribute (translated pages), else English. */
const msg = (form: HTMLFormElement, key: string, fallback: string) => form.dataset[key] || fallback;

for (const form of document.querySelectorAll<HTMLFormElement>('form.js-form')) {
  form.addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const status = form.querySelector<HTMLElement>('.form-status')!;
    const button = form.querySelector<HTMLButtonElement>('button[type=submit]')!;
    const endpoint = form.dataset.endpoint ?? '';
    if (!endpoint) return;
    if (!form.reportValidity()) return;

    const data = new FormData(form);
    const oneOf = (form.dataset.requireOne ?? '').split(',').filter(Boolean);
    if (oneOf.length && !oneOf.some((k) => String(data.get(k) ?? '').trim())) {
      status.className = 'form-status err';
      status.textContent = msg(form, 'msgRequireOne', 'Please fill in at least one of: {fields}.').replace('{fields}', oneOf.join(', '));
      return;
    }
    const token = String(data.get('cf-turnstile-response') ?? '');
    if (!token) {
      status.className = 'form-status err';
      status.textContent = msg(form, 'msgSpam', 'Please complete the spam check first.');
      return;
    }
    const fields: Record<string, string | string[]> = {};
    const consents: { key: string; text: string }[] = [];
    for (const [k, v] of data.entries()) {
      if (k === 'cf-turnstile-response' || k === 'website_url_confirm' || typeof v !== 'string') continue;
      const input = form.querySelector<HTMLInputElement>(`[name="${CSS.escape(k)}"]`);
      if (input?.dataset.consent) {
        consents.push({ key: k, text: input.dataset.consent });
        continue;
      }
      const prev = fields[k];
      fields[k] = prev === undefined ? v.trim() : ([] as string[]).concat(prev, v.trim());
    }
    const payload = {
      form: form.dataset.kind,
      country: form.dataset.country,
      page: location.pathname,
      submitted_at: new Date().toISOString(),
      fields,
      consents,
      honeypot: String(data.get('website_url_confirm') ?? ''),
      turnstile_token: token,
    };

    button.disabled = true;
    status.className = 'form-status';
    status.textContent = msg(form, 'msgSending', 'Sending...');
    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (res.status === 429) throw new Error(msg(form, 'msgTooMany', 'Too many attempts. Please wait a minute and try again.'));
      if (!res.ok) throw new Error(msg(form, 'msgFailed', 'Something went wrong. Please try again.'));
      const body = (await res.json().catch(() => ({}))) as { request_id?: string };
      if (form.dataset.kind === 'account_deletion' && body.request_id) showOtpStep(form, body.request_id);
      form.reset();
      status.className = 'form-status ok';
      status.textContent = form.dataset.success ?? 'Thank you.';
    } catch (err) {
      status.className = 'form-status err';
      status.textContent = err instanceof Error && err.message ? err.message : msg(form, 'msgNetwork', 'Network error. Please try again.');
    } finally {
      button.disabled = false;
      window.turnstile?.reset(form.querySelector('.cf-turnstile') ?? undefined);
    }
  });
}

/** Second step of web account deletion: confirm with the OTP sent to the registered phone. */
function showOtpStep(form: HTMLFormElement, requestId: string) {
  const step = form.nextElementSibling;
  if (!(step instanceof HTMLFormElement) || !step.classList.contains('js-otp-step')) return;
  step.hidden = false;
  step.dataset.requestId = requestId;
  step.querySelector<HTMLInputElement>('input[name=otp]')?.focus();
  if (step.dataset.bound) return;
  step.dataset.bound = '1';
  step.addEventListener('submit', async (ev) => {
    ev.preventDefault();
    if (!step.reportValidity()) return;
    const status = step.querySelector<HTMLElement>('.form-status')!;
    const button = step.querySelector<HTMLButtonElement>('button[type=submit]')!;
    const otp = String(new FormData(step).get('otp') ?? '').trim();
    button.disabled = true;
    status.className = 'form-status';
    status.textContent = 'Checking...';
    try {
      const res = await fetch(step.dataset.endpoint ?? '', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'confirm_deletion', request_id: step.dataset.requestId, otp }),
      });
      if (res.status === 429) throw new Error('Too many attempts. Please wait and try again.');
      if (res.status === 400) throw new Error('That code is wrong or has expired.');
      if (!res.ok) throw new Error('Something went wrong. Please try again.');
      step.reset();
      button.hidden = true;
      status.className = 'form-status ok';
      status.textContent = 'Your account has been deleted.';
    } catch (err) {
      status.className = 'form-status err';
      status.textContent = err instanceof Error && err.message ? err.message : 'Network error. Please try again.';
    } finally {
      button.disabled = false;
    }
  });
}

export {};
