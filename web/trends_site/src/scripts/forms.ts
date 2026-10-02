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
      status.textContent = 'Please fill in at least one of: ' + oneOf.join(', ') + '.';
      return;
    }
    const token = String(data.get('cf-turnstile-response') ?? '');
    if (!token) {
      status.className = 'form-status err';
      status.textContent = 'Please complete the spam check first.';
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
    status.textContent = 'Sending...';
    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      if (res.status === 429) throw new Error('Too many attempts. Please wait a minute and try again.');
      if (!res.ok) throw new Error('Something went wrong. Please try again.');
      form.reset();
      status.className = 'form-status ok';
      status.textContent = form.dataset.success ?? 'Thank you.';
    } catch (err) {
      status.className = 'form-status err';
      status.textContent = err instanceof Error && err.message ? err.message : 'Network error. Please try again.';
    } finally {
      button.disabled = false;
      window.turnstile?.reset(form.querySelector('.cf-turnstile') ?? undefined);
    }
  });
}

export {};
