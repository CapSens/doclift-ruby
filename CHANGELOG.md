[Unreleased]

v0.1.0
------

First release, covering the whole Doclift API v1 as served on 2026-08-24. The
client is a dependency-free layer over net/http, mirroring the architecture of
signlift-ruby: a global configuration, singleton resource modules returning
parsed hashes, and typed errors. Listings return a small Page object because
the API ships its pagination metadata in response headers, which raw hashes
would lose.

- `Doclift.configure` / `Doclift.client` / `Doclift.reset!`
- `Doclift::User.show`
- `Doclift::Templates` — list, find, create, update, destroy, publish, unpublish
- `Doclift::TemplateVariables` — list, create, update, destroy
- `Doclift::DocumentRequests` — list, find, create (synchronous and
  asynchronous), plus response readers hiding the request/response key
  asymmetry (`file_url`, `generation_status`, `generation_error`, `status`)
- `Doclift::Webhooks::SignatureVerifier` — X-Doclift-Signature verification
- `Doclift::Workflows::Capabilities` — the contract manifest
- `Doclift::Workflows::Templates` — CRUD, validate, payload_contract,
  publish/unpublish, document export and destructive replace, theme
- `Doclift::Workflows::Sections` — CRUD, move, duplicate, backgrounds
- `Doclift::Workflows::Variables`, `Doclift::Workflows::Datasets`,
  `Doclift::Workflows::Images` (token-addressed)
- `Doclift::Page`, typed error hierarchy, 100% line and branch coverage
