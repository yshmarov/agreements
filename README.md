# agreements

[![Gem Version](https://img.shields.io/gem/v/agreements)](https://rubygems.org/gems/agreements)
[![CI](https://github.com/yshmarov/agreements/actions/workflows/ci.yml/badge.svg)](https://github.com/yshmarov/agreements/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](MIT-LICENSE)

Record who accepted which version of your Terms, Privacy Notice or Data
Processing Agreement, and ask again when the documents change. For Rails.

```ruby
Agreements.pending_version("user_terms", subject: current_user)
# => nil when the user accepted the current Terms, or the version they still need to accept
```

## Why you need it

Most apps store terms acceptance as a timestamp, such as
`users.accepted_terms_at`. That works until somebody asks a real question:

- **Which version** of the Terms did this user accept, and what did it say?
- **What exactly did they tick?** In which language?
- **Who accepted for the company?** Was it the account owner or an ordinary
  member?
- **The Terms changed last month.** Who still has to accept the new version?
- **The form was open during a deploy.** Did the user accept the old version or
  the new one?

Procurement teams, auditors and lawyers ask these questions. A timestamp cannot
answer them. This gem can, with two database tables and a few method calls.

## What it looks like in your app

1. **First deploy.** Every signed-in user who has not accepted your Terms is
   sent to your acceptance page on their next page view. They tick the box and
   continue to the page they wanted.
2. **Your lawyer updates the Terms.** You publish the new document and add the
   new version with the date it takes effect, for example in 14 days. Nothing
   changes for users before that date. You can show a notice in the meantime.
3. **On the effective date,** each user is asked once to accept the new version.
4. **An auditor asks** "Who accepted the DPA for Acme, and what did they see?"
   You answer with one query:

```text
agreement:  organization_dpa, version 2026-09-13
subject:    gid://my-app/Organization/42      the party bound by the agreement
actor:      gid://my-app/User/7               the person who clicked
authority:  organization_owner                why that person could accept
statement:  "J'accepte le contrat de traitement des données au nom de cette organisation."
locale:     fr
accepted:   2026-09-14 09:12:03 UTC
```

Records cannot be changed or deleted through the model API.

## Is it for you?

**Use it when**

- you have Terms, a Privacy Notice or a DPA, and you must prove acceptance later;
- a company accepts an agreement through one of its users (B2B SaaS);
- your documents change, and you must ask people again;
- you show the acceptance checkbox in more than one language.

**Use something else when**

- you need signatures for contracts. Use an e-signature service;
- you need to record and withdraw GDPR consent, such as marketing consent;
- you need IP addresses, signed receipts or a ready-made form builder.
  [clickwrap](https://github.com/rameerez/clickwrap) covers that bigger scope.

## Trust

- **In production.** [EthicsPortal](https://ethicsportal.eu), whistleblower
  software for EU organisations, uses it for user Terms and organisation DPAs.
  The gem was extracted from that code in August 2026.
- **Small.** About 250 lines of Ruby. You can read all of it in one sitting.
- **Tested** in CI on every push: Ruby 3.2 to 4.0 with Rails 7.1 to 8.1 on
  SQLite, and Rails 8.1 on PostgreSQL.
- **Safe releases.** Releases are built and published from
  [GitHub Actions](.github/workflows/release.yml) with RubyGems trusted
  publishing. Gem ownership requires multi-factor authentication.
- **Few dependencies.** Action Pack, Active Record, Railties and Global ID. No
  JavaScript, no background jobs, no external services.
- **Your data stays in your database.** The gem makes no network calls and
  collects no telemetry. It does not store IP addresses or user agents.
- **Security:** see [SECURITY.md](SECURITY.md). Report vulnerabilities through
  [private reporting](https://github.com/yshmarov/agreements/security/advisories/new).
- **Changes** are listed in the [CHANGELOG](CHANGELOG.md). See
  [Versioning](#versioning) for what may break before 1.0.

## Quick start

Ruby 3.2 or later, Rails 7.1 or later. The example uses a `Current.user`, as
created by the Rails 8 authentication generator. Use your own current user.

### 1. Install

```ruby
# Gemfile
gem "agreements"
```

```bash
bundle install
bin/rails generate agreements:install
bin/rails db:migrate
```

The generator adds one migration with two tables: `agreements_versions` and
`agreements_acceptances`. It adds no routes, views or configuration.

### 2. Add your first version

A version is data that you deploy. Add it in a migration:

```ruby
# db/migrate/20260816000000_add_user_terms_2026_08_16.rb
class AddUserTerms20260816 < ActiveRecord::Migration[8.1]
  class Version < ActiveRecord::Base
    self.table_name = "agreements_versions"
  end

  VERSION = {
    agreement_key: "user_terms",
    version: "2026-08-16",
    acceptance_statement: "I accept the Terms of Service and acknowledge the Privacy Notice.",
    documents: [
      { key: "terms_of_service", title: "Terms of Service", url: "https://example.com/terms-2026-08-16" },
      { key: "privacy_notice", title: "Privacy Notice", url: "https://example.com/privacy-2026-08-16" }
    ]
  }.freeze

  def up
    version = Version.find_or_create_by!(VERSION.slice(:agreement_key, :version)) do |record|
      record.assign_attributes(VERSION)
    end

    unless version.acceptance_statement == VERSION[:acceptance_statement] &&
           version.documents == VERSION[:documents].as_json
      raise "#{version.agreement_key} #{version.version} already exists with different content"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Agreement versions are evidence"
  end
end
```

- Use your own Rails version in `Migration[8.1]`.
- The documents stay on your website. The gem stores only their title, URL and
  an optional SHA-256 digest.
- The migration defines its own model, so it keeps working when the gem changes.
- The final check stops a deploy if the version already exists with different
  content. A deployed version must never change.
- Add the same versions to `db/seeds.rb`, so a fresh database has them too.

### 3. Add the acceptance page

```ruby
# config/routes.rb
resource :terms_acceptance, only: %i[show create]
```

```ruby
# app/controllers/terms_acceptances_controller.rb
class TermsAcceptancesController < ApplicationController
  skip_before_action :require_terms

  def show
    @version = Agreements.current_version("user_terms")
    raise ActiveRecord::RecordNotFound unless @version
  end

  def create
    @version = Agreements.current_version("user_terms")
    return render(:show, status: :unprocessable_content) unless params.dig(:acceptance, :confirmed) == "1"

    Agreements.accept!(
      "user_terms",
      version_id: params.dig(:acceptance, :agreement_version_id),
      subject: Current.user,
      actor: Current.user,
      authority: "self",
      acceptance_statement: t("terms_acceptances.statement"),
      locale: I18n.locale.to_s
    )
    redirect_to agreement_return_location || root_path, status: :see_other
  rescue Agreements::VersionNotCurrent => error
    raise ActiveRecord::RecordNotFound unless error.current_version

    @version = error.current_version
    flash.now[:alert] = t("terms_acceptances.changed")
    render :show, status: :unprocessable_content
  end
end
```

```erb
<%# app/views/terms_acceptances/show.html.erb %>
<%= form_with scope: :acceptance, url: terms_acceptance_path do |form| %>
  <%= form.hidden_field :agreement_version_id, value: @version.id %>

  <%= form.label :confirmed do %>
    <%= form.check_box :confirmed, required: true %>
    <%= t("terms_acceptances.statement") %>
  <% end %>

  <ul>
    <% @version.documents.each do |document| %>
      <li><%= link_to document["title"], document["url"], target: "_blank" %></li>
    <% end %>
  </ul>

  <%= form.submit t("terms_acceptances.accept") %>
<% end %>
```

```yaml
# config/locales/en.yml
en:
  terms_acceptances:
    statement: I accept the Terms of Service and acknowledge the Privacy Notice.
    accept: Accept and continue
    changed: The Terms changed while this page was open. Please review them again.
```

- `require_terms` is defined in step 4. Add both steps before you restart the
  server.
- The hidden field sends the version the user saw. If a newer version became
  current in the meantime, `accept!` raises `Agreements::VersionNotCurrent` and
  the page shows the new version.
- `acceptance_statement` is the exact sentence the user saw, in their language.
  It is stored with the acceptance.
- Pass `subject`, `actor` and `authority` from the server. Never take them from
  request parameters.
- A double click or a retry returns the first acceptance. It does not create a
  second one.

### 4. Require acceptance

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Agreements::Enforcement

  before_action :require_terms, if: -> { Current.user }

  private

  def require_terms
    require_agreement("user_terms", subject: Current.user, location: main_app.terms_acceptance_path)
  end
end
```

When the user has not accepted the current version:

- an HTML or Turbo Stream request is redirected to the acceptance page. After
  acceptance, `agreement_return_location` sends the user back to the page they
  asked for (GET and HEAD requests only; a form submission is never replayed);
- any other request (JSON, CSV, PDF) gets an empty `403 Forbidden`.

Use `main_app.` for the location so the check also works inside mounted
engines.

### 5. Update your tests

With enforcement on, most tests need users who have already accepted:

```ruby
# test/test_helper.rb
require "agreements/test_helper"

class ActiveSupport::TestCase
  include Agreements::TestHelper
end
```

```ruby
accept_agreement("user_terms", subject: users(:alice))
```

Add the current versions to your fixtures or test setup first. The helper raises
when no current version exists.

## Guides

### Agreements for a company (DPA)

The organisation is the **subject**: it is bound by the agreement. The user who
clicks is the **actor**. Check in your app that the actor may accept, then
record the authority you checked:

```ruby
Agreements.accept!(
  "organization_dpa",
  version_id: params.dig(:acceptance, :agreement_version_id),
  subject: Current.organization,
  actor: Current.user,
  authority: "organization_owner",
  acceptance_statement: t("dpa_acceptances.statement", organization: Current.organization.name),
  locale: I18n.locale.to_s
)
```

The acceptance belongs to the organisation. If ownership moves to another user
later, the organisation does not have to accept again.

`require_agreement` returns `nil`, `:redirected` or `:forbidden`. Use it to
skip work after a halted request, for example Pundit's `verify_authorized`:

```ruby
skip_authorization if require_agreement("organization_dpa", subject: Current.organization, location: dpa_path)
```

### Change your Terms with notice

Terms often promise notice before a change applies, such as "at least 14 days
before the changes take effect". Add the new version when you send the notice,
with the date it takes effect:

```ruby
VERSION = {
  agreement_key: "user_terms",
  version: "2026-12-01",
  effective_at: Time.utc(2026, 12, 1),
  acceptance_statement: "I accept the Terms of Service and acknowledge the Privacy Notice.",
  documents: [{ key: "terms_of_service", title: "Terms of Service", url: "https://example.com/terms-2026-12-01" }]
}.freeze
```

- Until `effective_at`, the previous version stays current. Nobody is asked to
  accept, and `accept!` refuses the new version.
- `Agreements.upcoming_version("user_terms")` returns the scheduled version, so
  you can show a notice in the app.
- From `effective_at`, the new version is current, and everyone who has not
  accepted it is asked once.
- Without `effective_at`, a version is current as soon as it is inserted.
- The current version is the one that took effect most recently. If two take
  effect at the same time, the one inserted later wins.
- To cancel a scheduled version before its date, delete it in a data migration
  with a migration-local model. It cannot have acceptances yet.
- Publish the new document URL before the version takes effect. Use a new URL
  for each version, so old acceptances keep pointing at the text people saw.

### Show translated document links

Give each document a `key`. Look up the link title in your locale files, so
your views do not depend on the English `title`:

```erb
<% @version.documents.each do |document| %>
  <%= link_to t("documents.#{document["key"]}"), document["url"] %>
<% end %>
```

### APIs and JSON

`require_agreement` answers non-HTML requests with an empty `403`. If your API
has its own error format, check first:

```ruby
def require_dpa
  if api_request?
    if Agreements.pending_version("organization_dpa", subject: Current.organization)
      render json: { error: "agreement_required" }, status: :forbidden
    end
    return
  end

  require_agreement("organization_dpa", subject: Current.organization, location: main_app.dpa_path)
end
```

### Answer an audit request

Acceptances are ordinary Active Record rows:

```ruby
Agreements::Acceptance
  .includes(:agreement_version)
  .where(subject_key: organization.to_global_id.to_s)
  .order(:accepted_at)
```

The gem has no admin screen and no export. Build one when a real audit tells
you which format and access controls it needs.

### Keep subject keys stable

Subjects and actors are stored as Global ID strings, such as
`gid://my-app/User/1`. The string contains your app name and the model class.
If either changes, old acceptances no longer match and everyone is asked again.
Pin the app name now:

```ruby
# config/application.rb
config.global_id.app = "my-app"
```

Before you rename a model, plan how to carry its acceptances over. You can also
pass your own non-empty string as subject or actor.

## API reference

### Module methods

| Method | Returns |
|---|---|
| `Agreements.current_version(key)` | The `Agreements::Version` in effect now, or `nil` |
| `Agreements.upcoming_version(key)` | The next scheduled version, or `nil` |
| `Agreements.pending_version(key, subject:)` | The current version if `subject` has not accepted it, otherwise `nil` |
| `Agreements.accept!(key, version_id:, subject:, actor:, authority:, acceptance_statement:, locale:)` | The new or existing `Agreements::Acceptance` |
| `Agreements.identity_key(record_or_string)` | The stored key for a subject or actor |

`accept!` raises:

- `Agreements::VersionNotCurrent` when `version_id` is missing, malformed, for
  another agreement or no longer current. `error.current_version` is the
  version to show, or `nil` when none exists;
- `Agreements::InvalidIdentity` when a subject or actor is neither a non-empty
  string nor a record with `to_global_id`;
- `ActiveRecord::RecordInvalid` when `authority`, `acceptance_statement` or
  `locale` is blank, or `authority` has characters other than `a-z`, `0-9` and `_`.

### Controller methods (`include Agreements::Enforcement`)

| Method | Behaviour |
|---|---|
| `require_agreement(key, subject:, location:)` | `nil` when nothing is pending. Otherwise redirects HTML and Turbo Stream requests to `location` (returns `:redirected`) or renders `403` for others (returns `:forbidden`) |
| `agreement_return_location` | The same-origin path saved by `require_agreement`, read once, or `nil` |

### Test helper (`require "agreements/test_helper"`)

| Method | Behaviour |
|---|---|
| `accept_agreement(key, subject:, actor: subject, authority: "self", locale: "en")` | Accepts the current version with its canonical statement |

### Models

`Agreements::Version`

| Attribute | Notes |
|---|---|
| `agreement_key` | `a-z`, `0-9` and `_`, for example `user_terms` |
| `version` | Your label, for example `2026-08-16`. Unique per key |
| `acceptance_statement` | The canonical statement for this version |
| `documents` | At least one `{ title:, url:, sha256:, key: }`. `url` must be HTTPS. `sha256` and `key` are optional |
| `effective_at` | Optional. The version is current from this time |

`Agreements::Acceptance`

| Attribute | Notes |
|---|---|
| `agreement_version` | The accepted version |
| `subject_key`, `actor_key` | Global ID strings or your own strings |
| `authority` | Why the actor could accept, for example `self` or `organization_owner` |
| `acceptance_statement`, `locale` | The exact sentence shown and its language |
| `accepted_at` | Server time of acceptance |

Both models are read-only once saved. Updates and deletes through the model API
raise `ActiveRecord::ReadOnlyRecord`. A database user with direct SQL access
can still change rows.

## What the evidence proves

The gem records which version and which sentence a subject accepted, who did
it, under what authority, and when. Some questions it cannot answer for you:

- **The whole page counts.** Courts look at the entire screen, not only the
  checkbox. In *Berman v. Freedom Financial Network* (9th Cir. 2022) the terms
  did not bind the user: the notice was small grey text, the links did not
  look like links, and the button said "Continue" without saying that it meant
  acceptance. Your layout, contrast and button text decide this.
- **It is not a qualified electronic signature.** Under eIDAS (Regulation (EU)
  No 910/2014, Article 25), an electronic signature cannot be denied legal
  effect only because it is electronic or not qualified. A checkbox is still
  not a qualified electronic signature, and this gem does not create one.
- **Acknowledging a privacy notice is not consent.** Under the GDPR you inform
  people (Article 13). Consent (Articles 6 and 7) is a separate, specific
  choice that people can withdraw. Keep the two apart.
- **The text of your terms still matters.** In the EU, an unfair term in a
  consumer contract does not bind the consumer (Directive 93/13/EEC), however
  clearly it was accepted.
- **Identity and authority are your checks.** The gem stores the actor and the
  authority you pass. It does not verify who the person is or whether they may
  bind an organisation.

Your lawyer decides what your agreements need. The gem keeps the record.

## What this gem does not do

- Host, edit or render legal documents.
- Drafts, approval workflows or an admin dashboard.
- Electronic signatures or identity checks.
- IP addresses, user agents or other request data.
- Consent withdrawal, retention rules or reports.
- Your routes, views, copy, onboarding or authorization.

## Versioning

The gem follows semantic versioning. Before 1.0, a minor release (0.x.0) may
change behaviour or the schema. Each such release lists the change and the
upgrade steps in the [CHANGELOG](CHANGELOG.md) and below. Patch releases
(0.x.y) never break your app.

### Upgrading from 0.3

Version 0.4 adds a nullable `effective_at` column to `agreements_versions`:

```bash
bin/rails generate migration AddEffectiveAtToAgreementsVersions effective_at:datetime
bin/rails db:migrate
```

Existing rows keep `effective_at` empty and stay in effect from their creation.

### Upgrading from 0.2

Version 0.3 has no schema change. `require_agreement` now answers a pending
non-HTML request with `403 Forbidden` instead of letting it through. If your
API already checks `pending_version` before calling it, nothing changes.

### Upgrading from 0.1

Version 0.2 adds non-null `acceptance_statement` and `locale` columns to
`agreements_acceptances`. Add them in a migration before upgrading. For existing
rows, copy each version's canonical statement and use `und` as the locale when
the displayed language is unknown.

## Contributing

Bug reports and pull requests are welcome on
[GitHub](https://github.com/yshmarov/agreements/issues). See
[CONTRIBUTING.md](CONTRIBUTING.md) for setup and scope.

## License

[MIT](MIT-LICENSE). Maintained by [Yaroslav Shmarov](https://github.com/yshmarov).
