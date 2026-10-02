# Backend needs (status)

All items the admin panel asked for are now in `supabase/migrations/` (see `supabase/API.md`):

1. `admin_audit_log` (append-only, written server side by every admin RPC and by triggers): done.
2. `admin_kpis()`: done. Revenue KPIs stay empty until the admin fills `kpi_product_prices_minor`.
3. `outreach-send` action `send_one`: done (admin JWT only, re-runs every anti-spam check server side).
4. `outreach_business_address` setting: done. Sends stay blocked while it is a placeholder.
5. `admin_outreach_set_stage`: done; the panel calls it for every stage move.
6. Remote Config sync: not needed. The apps read flags from `get_app_settings()`.
7. SEO pages (Section 21.9): `seo_pages`, `seo_export_runs`, `seo_guides`, `admin_set_seo_page_noindex`, `admin_upsert_seo_guide`, `admin_review_seo_guide`, the `seo_thresholds` / `seo_ai_guides_weekly_cap` settings and the `seo-export` Edge Function: done (migrations 1100 and 1110). Still missing: Search Console traffic / conversions per page.

After deploying to a hosted project: fill in `outreach_business_address`, and have an admin activate campaigns (every campaign starts as a draft).
