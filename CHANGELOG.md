# Changelog

## 1.0.6

- Carrier Lock text now follows the system language. The tweak reuses
  Apple's own localized `CARRIER_LOCK_UNLOCKED` (and
  `CARRIER_LOCK_UNLOCKED_DETAILS` when present) strings instead of
  hardcoded Vietnamese text, so every device language shows its native
  "No SIM restrictions" wording.
- Carrier Lock row detection no longer depends on Vietnamese strings; it
  matches the localized unlocked text.

## 1.0.5

- Updated the package author and maintainer to **Nam Pank**.
- Added a simple, fun and honest package description for Sileo/Zebra.
- Refreshed the README without changing the tweak's runtime behavior.

## 1.0.4

- Renamed the project to **Carrier Locked change to Unlocked**.
- Preserved the package ID so this release upgrades earlier CarrierLockText
  installations instead of creating a duplicate package.
- Preserved the localization and non-selectable Carrier Lock row behavior from
  version 1.0.3.
