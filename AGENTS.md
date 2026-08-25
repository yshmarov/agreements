# AGENTS.md

## Purpose

`agreements` records auditable acceptance of externally hosted legal documents
in Rails. Keep the gem smaller than the applications adopting it.

## Commands

```bash
bundle install
bundle exec rake test
bundle exec rubocop
bundle exec rake build
```

## Boundary

- Persist only immutable agreement versions and append-only acceptances.
- Keep legal documents external; store title, HTTPS URL, and optional SHA-256.
- Keep actor and subject separate, with explicit authority and server time.
- Accept only the submitted version while it remains current.
- Leave authentication, authorization, tenancy, routes, controllers, views,
  onboarding, marketing consent, and legal copy in the host.
- Do not add a configuration DSL, document CMS, admin dashboard, provenance,
  presentation manifests, lifecycle engine, or reporting system speculatively.

## Version lifecycle

The newest inserted version for an agreement key is current. A later version is
a host data migration plus the same entry in host seeds. Never mutate or reuse a
deployed version label.

## Tests

Cover evidence integrity, actor/subject identity, idempotency, stale and
wrong-agreement submissions, external-document validation, immutability, safe
return paths, and mutation non-replay. Do not test host-specific copy or CSS.

## Shipping

Preserve unrelated work. Do not commit, push, publish, or merge unless the user
asked. Never publish a gem release merely because the test suite passes.
