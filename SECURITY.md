# Security

Report vulnerabilities privately through GitHub's security advisory feature.

The gem resolves actor, subject, authority, and acceptance time from values the
host passes server-side. A submitted version ID is accepted only when it matches
the current version for the expected agreement key.

Persisted records are read-only through the model API. This does not protect
against a privileged database owner or direct SQL mutation.
