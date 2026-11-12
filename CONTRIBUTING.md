# Contributing

`agreements` records auditable acceptance of externally hosted legal documents
in Rails. It should stay smaller than the applications that use it.

## Setup

```bash
bundle install
bundle exec rake test
bundle exec rubocop
```

Run the suite against one Rails version from the CI matrix:

```bash
BUNDLE_GEMFILE=gemfiles/rails_7.1.gemfile bundle exec rake test
```

The suite uses in-memory SQLite. CI also runs it on PostgreSQL; to do the
same locally, point `DATABASE_URL` at an empty database:

```bash
createdb agreements_test
DATABASE_URL=postgres://localhost/agreements_test bundle exec rake test
```

## Scope

- Persist only immutable agreement versions and append-only acceptances.
- Keep legal documents external: store a title, HTTPS URL, optional SHA-256
  and optional key.
- Store the exact localized statement shown by the host and its locale.
- Keep actor and subject separate, with explicit authority and server time.
- Accept only the submitted version while it remains current.
- Leave authentication, authorization, tenancy, routes, controllers, views,
  onboarding, marketing consent and legal copy in the host.
- No configuration DSL, document CMS, admin dashboard, request provenance,
  lifecycle engine or reporting system without a concrete need from a real
  application.

The newest inserted version for an agreement key is current. A later version is
a host data migration plus the same entry in host seeds. A deployed version
label is never changed or reused.

## Tests

Cover evidence integrity, actor and subject identity, idempotency, stale and
wrong-agreement submissions, document validation, immutability, safe return
paths and mutation non-replay. Host copy and CSS are out of scope.

## Releases

Update `CHANGELOG.md` and `lib/agreements/version.rb`, then push a `vX.Y.Z` tag.
The release workflow runs the tests and publishes to RubyGems through trusted
publishing.
