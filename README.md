# agreements

Auditable acceptance of externally hosted legal agreements for Rails.

`agreements` answers one durable question:

> Which agreement version and localized statement did this subject accept,
> who performed the acceptance, under what authority, and when?

It deliberately does not host legal documents or provide a legal CMS. Your
legal or marketing site remains authoritative; the gem stores immutable
version metadata and append-only acceptance evidence in your own database.

## Install

```ruby
# Gemfile
gem "agreements"
```

```bash
bundle install
bin/rails generate agreements:install
bin/rails db:migrate
```

The generator adds two tables and nothing else. There is no route, controller,
view, initializer, JavaScript, CSS, or admin dashboard to integrate.

Ruby >= 3.2 · Rails >= 7.1 and < 9 · PostgreSQL and SQLite

### Upgrading from 0.1

Version 0.2 adds non-null `acceptance_statement` and `locale` columns to
`agreements_acceptances`. Add them in a host migration before upgrading. For
existing evidence, copy each version's canonical statement and use an honest
locale such as `und` when the displayed locale is unknown.

## Define a version

Agreement versions are deployed data. Create them in a data migration and keep
the same registry in your seeds for fresh databases:

```ruby
Agreements::Version.create!(
  agreement_key: "user_terms",
  version: "2026-08-16",
  acceptance_statement: "I accept the Terms of Service and acknowledge the Privacy Notice.",
  documents: [
    { title: "Terms of Service", url: "https://example.com/terms" },
    { title: "Privacy Notice", url: "https://example.com/privacy" }
  ]
)
```

The newest inserted row for an agreement key is current immediately. There is
no draft, publish, activate, or scheduling lifecycle. A correction or legal
update is a new immutable row with a new version label.

Document references accept `title`, an HTTPS `url`, and an optional 64-character
`sha256`. The gem validates a supplied digest but does not fetch remote pages,
calculate hashes, or retain document bytes. Hashing and archival belong in the
trusted legal-document publishing process.

## Ask what is pending

```ruby
version = Agreements.current_version("user_terms")
pending = Agreements.pending_version("user_terms", subject: current_user)
```

Subjects and actors may be records responding to `to_global_id`, or explicit
non-empty opaque strings. The gem stores only the resulting keys; it does not
own authentication, tenancy, roles, or authorization.

## Render the host-owned form

Keep the page, routes, authorization, document-link markup, and copy in your
application. Submit the exact displayed version as a hidden field:

```erb
<%= form.hidden_field :agreement_version_id, value: @version.id %>
<%= form.check_box :confirmed, required: true %>
```

Then record only that version while it remains current:

```ruby
statement = I18n.t("agreements.user_terms.statement")

acceptance = Agreements.accept!(
  "user_terms",
  version_id: params.dig(:acceptance, :agreement_version_id),
  subject: current_user,
  actor: current_user,
  authority: "self",
  acceptance_statement: statement,
  locale: I18n.locale.to_s
)
```

`Agreements.accept!` resolves the current version server-side, requires the
submitted ID to match it, derives opaque keys from the server-owned subject and
actor, and records the exact localized plain-text statement selected by the
host. Do not accept either value from browser parameters. Retries, double
clicks, and concurrent submissions return the original acceptance evidence.

A missing, malformed, wrong-agreement, or stale ID raises
`Agreements::VersionNotCurrent`. Its `current_version` is ready to render:

```ruby
rescue Agreements::VersionNotCurrent => error
  @version = error.current_version
  render :show, status: :unprocessable_content
end
```

Authorization stays in the host. For an organization DPA, for example, verify
the actor is the current owner before calling:

```ruby
Agreements.accept!(
  "organization_dpa",
  version_id: params.dig(:acceptance, :agreement_version_id),
  subject: current_organization,
  actor: current_user,
  authority: "organization_owner",
  acceptance_statement: I18n.t("agreements.organization_dpa.statement"),
  locale: I18n.locale.to_s
)
```

Uniqueness belongs to the organization subject, so a later ownership transfer
does not invalidate an existing acceptance.

## Enforce an agreement

Include the small controller concern in your application controller:

```ruby
class ApplicationController < ActionController::Base
  include Agreements::Enforcement
end
```

Call it from a host-owned before action after authentication and tenant context
are established:

```ruby
def require_organization_dpa
  require_agreement(
    "organization_dpa",
    subject: Current.organization,
    location: organization_dpa_path(Current.organization)
  )
end
```

It redirects pending HTML/Turbo requests and remembers only GET or HEAD return
locations. A blocked mutation is never replayed after acceptance. Consume the
safe same-origin path after a successful acceptance:

```ruby
redirect_to agreement_return_location || dashboard_path
```

API and headless behavior remains host-owned: use `pending_version` and return
the response contract your application supports.

## Evidence model

`agreements_versions` contains:

- agreement key;
- human version label;
- exact acceptance statement;
- external document references and optional SHA-256 digests;
- timestamps.

`agreements_acceptances` contains:

- agreement-version foreign key;
- opaque subject and actor keys;
- authority;
- exact localized acceptance statement and locale;
- server acceptance time;
- timestamps.

Persisted versions and acceptances are read-only through the model API. The gem
does not claim protection from a privileged database owner.

For an exceptional audit request, query ordinary Active Record rows:

```ruby
Agreements::Acceptance
  .includes(:agreement_version)
  .where(subject_key: current_organization.to_global_id.to_s)
```

Build an export only when a real audit defines the required format and access
controls.

## Shipping version two

1. Publish immutable/versioned legal-document URLs and any verified digests.
2. Add the finished bundle to the host's seed registry.
3. Add a host data migration that inserts the same immutable version.
4. Deploy. The new row becomes current and subjects missing it are prompted.

Production deployments normally run migrations, not seeds. Changing a seed
registry alone does not deploy a new version to an existing installation.

## Not this gem

- Legal-document hosting, editing, rendering, uploads, or a CMS.
- Draft/publish/activation workflows or an admin dashboard.
- Electronic signatures or identity proofing.
- IP addresses, user agents, fingerprints, geolocation, or request provenance.
- Presentation manifests, browser snapshots, scroll tracking, or one-time nonces.
- Consent withdrawal, declarations, attestations, authorizations, retention,
  legal holds, integrity chains, or compliance reporting.
- Application-specific onboarding, marketing consent, tenancy, ownership,
  layouts, routes, or copy.

Those are real product categories. They are not prerequisites for proving an
ordinary Terms or organization-DPA acceptance.

## Later, only after a concrete trigger

- **Atomic protected actions:** if evidence must accompany a payout, data
  handoff, or contract execution, commit the evidence and action in one
  transaction.
- **Standalone receipts:** if counsel or an auditor requests a repeatable
  package, export the smallest proven evidence set as canonical JSON or HTML.
- **Automated digest verification:** if exact bytes must be reproduced, verify
  and archive them in the trusted document-publishing pipeline, not during a
  user's acceptance request.

## License

MIT.
