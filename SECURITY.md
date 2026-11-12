# Security

## Reporting

Report vulnerabilities privately through
[GitHub private reporting](https://github.com/yshmarov/agreements/security/advisories/new).
Do not open a public issue.

## Supported versions

Security fixes go to the latest release. Before 1.0 that is the latest 0.x
version.

## Scope

The gem resolves actor, subject, authority, and acceptance time from values the
host passes server-side. A submitted version ID is accepted only when it matches
the current version for the expected agreement key.

Persisted records are read-only through the model API. This does not protect
against a privileged database owner or direct SQL mutation.
