#!/usr/bin/env bash
# Copies the brand marks the admin panel and its PDF brochures use from the
# repo-level branding/ folder (the single source of truth, Section 18).
# Flutter assets must live inside the package, so run this after a logo swap.
# Brand colours are mirrored in lib/core/config/admin_country.dart.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
for c in usa india; do
  mkdir -p "$here/assets/branding/$c"
  cp "$here/../branding/$c/logo/logo_mark_1024.png" "$here/assets/branding/$c/logo_mark_1024.png"
done
echo "Branding synced into admin/assets/branding/"
