# Changelog

## 0.3.0 - 2026-11-12

- Answer pending non-HTML requests with `403 Forbidden` instead of letting them
  through. `require_agreement` returns `:forbidden` for them.
- Reject `/\host` return paths, using Rails' `url_from`.
- Accept an optional `key` on document references for translated link titles.
- Depend on Action Pack, Active Record, Railties and Global ID instead of all
  of Rails.
- Document the safe data-migration pattern, Global ID app pinning and a `nil`
  `current_version` on `VersionNotCurrent`.

## 0.2.0 - 2026-08-27

- Record the exact localized acceptance statement and locale shown by the host.
- Publish releases through RubyGems trusted publishing.

## 0.1.0 - 2026-08-25

- Extract the agreement-version and acceptance primitives proven in EthicsPortal.
