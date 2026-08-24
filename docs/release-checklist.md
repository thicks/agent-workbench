# Release Checklist

Automated (CI / `tests/`):

- `./tests/install-smoke.sh` — clean install, C1–C3, ICM absence, idempotence
- `./tests/install-personal-manifest.sh` — personal manifest + C4
- `./tests/check-duplicates.py` — one body per skill name (M4)
- `./tests/check-docs.py` — docs match the tree, relative links, command→skill map (M5)

Manual:

- Confirm GitHub `main` requires a pull request (M6 / M8)
- Summarize changes and known limitations in release notes
