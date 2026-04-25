#!/bin/sh
set -eu

# Restore the pristine build with placeholders, then resolve them from the
# current environment. Done on every start so that changing PUBLIC_* env
# vars and restarting the container actually takes effect.
rm -rf /app/build
cp -R /app/build-template /app/build

replace() {
  name="$1"
  placeholder="__${name}__"
  value="$(printenv "$name" 2>/dev/null || echo '')"
  # Escape characters that are special to sed's replacement side, plus the
  # delimiter (|) we picked for the s command.
  escaped="$(printf '%s' "$value" | sed -e 's/[\\|&]/\\&/g')"
  find /app/build -type f \
    \( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' \
       -o -name '*.html' -o -name '*.json' -o -name '*.css' \) \
    -exec sed -i "s|${placeholder}|${escaped}|g" {} +
}

replace PUBLIC_ENV
replace PUBLIC_PRODUCTION_URL
replace PUBLIC_IMGIX_CDN_URL

exec "$@"
