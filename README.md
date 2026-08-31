# doclift-ruby

Ruby client for the [Doclift](https://www.doclift.io) document generation API: templates, variables, document requests (synchronous and asynchronous), workflow templates and webhook signature verification.

The gem is a thin, dependency-free layer over `net/http`. Endpoints return the parsed JSON `Hash` (or a `Doclift::Page` for paginated listings); knowledge of the response shapes stays in this gem through small reader functions, and HTTP failures become a small hierarchy of typed errors.

## Installation

The gem is not published on RubyGems: consumers install it from this repository, pinned to a tag.

```ruby
# Gemfile
git_source(:capsens) { |repo| "git@github.com:CapSens/#{repo}.git" }

gem "doclift", capsens: "doclift-ruby", tag: "v0.1.0"
```

## Configuration

```ruby
# config/initializers/doclift.rb
Doclift.configure do |config|
  config.api_key = ENV["DOCLIFT_API_KEY"] # the X-Api-Key of an external application
end
```

Everything else has a sensible default:

| Setting | Default | Notes |
|---|---|---|
| `api_url` | `https://app.doclift.io/api/v1` | |
| `open_timeout` | `5` | seconds |
| `read_timeout` | `120` | generous on purpose: a synchronous generation renders the PDF inside the request |
| `write_timeout` | `60` | raise it when uploading large base64 images on a slow link |
| `logger` | null logger | set a real one to get a debug line per request |

The environment (sandbox or production) is a property of the API key, not of the URL: a sandbox key hits the same host, is forced to low priority and gets watermarked PDFs.

`Doclift.reset!` drops the memoized configuration and client — see [Testing an application that embeds this gem](#testing-an-application-that-embeds-this-gem).

## Generating documents

A document request carries one or more generations, each pairing a published template with a flat hash of variables.

Synchronous — the response already contains the file, so budget the read timeout for it:

```ruby
response = Doclift::DocumentRequests.create(
  type: Doclift::DocumentRequests::TYPE_SYNCHRONOUS, # exactly one generation
  generations: [
    {template_id: 124, variables: {nom: "Dupont", prenom: "Marie"}},
  ],
)

Doclift::DocumentRequests.file_url(response) # presigned S3 URL, valid 2 hours
```

Asynchronous — requires a webhook URL on the external application; the API answers immediately and completion arrives through the webhook (`Doclift::DocumentRequests.find(id)` works as a polling fallback):

```ruby
response = Doclift::DocumentRequests.create(
  type: Doclift::DocumentRequests::TYPE_ASYNCHRONOUS,
  priority: "default", # critical (default) / default / low — also the queue name
  tag: "batch-2026-08",
  generations: [
    {template_id: 124, tag: "client-42", variables: {nom: "Dupont"}},
  ],
)

Doclift::DocumentRequests.status(response) # "in_progress"
```

The request payload key is `document_generations` while the response key is `documents_generations`; the readers (`file_url`, `generation_status`, `generation_error`, `status`) exist so callers never meet that asymmetry. Generated files are purged server-side after 15 days: download what you need to keep.

## Receiving webhooks

Doclift signs each webhook with HMAC-SHA256 over the raw body, keyed with the same secret as `X-Api-Key`, in the `X-Doclift-Signature` header:

```ruby
class DocliftWebhooksController < ActionController::API
  def create
    unless Doclift::Webhooks::SignatureVerifier.valid?(
      raw_body: request.raw_post,
      header: request.headers["X-Doclift-Signature"],
      secret: Doclift.configuration.api_key,
    )
      return head :unauthorized
    end

    payload = JSON.parse(request.raw_post)
    url = Doclift::DocumentRequests.file_url(payload)
    # ... download and attach the file ...
    head :ok
  end
end
```

There is one event only — a document request finished (success or error) — with the same payload as the synchronous create response. Answer 2xx within 3 seconds; failures are retried with exponential backoff (30 s, 60 s, ... capped at 30 min), 3 replays by default.

## Templates and variables

Reads span every published template; writes only reach `custom` templates (a `fillable_form` or `workflow` id answers 404 — workflows are edited through `Doclift::Workflows::*`).

```ruby
Doclift::Templates.list(page: 2)      # Doclift::Page
Doclift::Templates.find(124)
Doclift::Templates.create(title: "Contrat", description: "...", content: "<p>...</p>")
Doclift::Templates.update(124, title: "Avenant")
Doclift::Templates.publish(124)
Doclift::Templates.unpublish(124)
Doclift::Templates.destroy(124)       # archives, 204

Doclift::TemplateVariables.list(template_id: 124)
Doclift::TemplateVariables.create(
  template_id: 124,
  title: "civilite", description: "Civilité", field_type: "select",
  allowed_values: ["M", "Mme"], seed_value: "Mme",
)
Doclift::TemplateVariables.update(template_id: 124, id: 9, seed_value: "M")
Doclift::TemplateVariables.destroy(template_id: 124, id: 9)
```

`Doclift::User.show` returns the identity behind the key, its limits and the current external application.

## Workflows

The workflow builder's whole API surface is covered. One behaviour rules the namespace: while a human holds the builder's edit lock, every write answers **409** (`Doclift::ConflictError`). The lock goes stale 3 minutes after the last heartbeat, so a 409 is transient — back off and retry, or check `being_edited` on the template.

```ruby
Doclift::Workflows::Capabilities.show   # the contract manifest: enums, limits, fonts

Doclift::Workflows::Templates.list
Doclift::Workflows::Templates.create(title: "Relevé annuel", description: "...")
Doclift::Workflows::Templates.validate(124, content: ["<p>...</p>"], scope: "content")
Doclift::Workflows::Templates.payload_contract(124) # ready-to-post example payload
Doclift::Workflows::Templates.publish(124)          # 422 lists the blocking anomalies
Doclift::Workflows::Templates.document(124)         # full export manifest
Doclift::Workflows::Templates.replace_document(124, manifest) # destructive replace
Doclift::Workflows::Templates.theme(124)
Doclift::Workflows::Templates.update_theme(124, {h1: {font_size: "22pt"}})

Doclift::Workflows::Sections.create(template_id: 124, kind: "rich_content", title: "Corps", parent_id: 500)
Doclift::Workflows::Sections.move(template_id: 124, id: 512, parent_id: 500, position: 2)
Doclift::Workflows::Sections.update_background(
  template_id: 124, section_id: 512,
  filename: "cerfa.png", content_type: "image/png", data: base64_data,
)

Doclift::Workflows::Variables.create(
  template_id: 124,
  name: "investissements", description: "Les lignes", field_type: "collection",
  fields: [{name: "produit", description: "Le produit", required: true}],
)
Doclift::Workflows::Datasets.create(template_id: 124, name: "Particulier", values: {nom: "Dupont"})
Doclift::Workflows::Images.create(template_id: 124, filename: "logo.png", content_type: "image/png", data: base64_data)
```

Points that are easy to trip on:

- Section and theme writes sanitise silently: the API answers 200 and drops what it refuses. Read the response back (or run `validate` first) rather than assume the write landed verbatim.
- Workflow variables travel as `name` on the wire and must already match `/\A[a-z0-9_]+\z/` — the API refuses instead of downcasing.
- Images are addressed by their 32-character `token`, not the numeric `id` their payload also carries; the `url` is a relative path meant to go straight into the content's `<img src>`.
- `replace_document` wipes and rebuilds the whole workflow from the manifest in one transaction; anything the manifest omits is deleted.

## Pagination

The three paginated listings (`Templates.list`, `DocumentRequests.list`, `Workflows::Templates.list`) return a `Doclift::Page`: an `Enumerable` over the raw item hashes with `current_page`, `pages_count`, `total_results`, `per_page` (30, fixed server-side) and `next_page?`. The API sends this metadata in response headers and omits it on an empty document requests listing, so all of it is nilable and `next_page?` answers `false` when unknown.

```ruby
page = 1
loop do
  result = Doclift::Templates.list(page: page)
  result.each { |template| ... }
  break unless result.next_page?
  page += 1
end
```

## Errors

Everything raised by the gem descends from `Doclift::Error`.

| Class | Raised on |
|---|---|
| `Doclift::ConfigurationError` | missing `api_key`, raised before any request leaves the process |
| `Doclift::ConnectionError` | any transport failure (timeouts, refused, DNS, TLS); `#cause_class` names the original |
| `Doclift::BadRequestError` | 400 — malformed JSON body or missing root key |
| `Doclift::AuthenticationError` | 403 — the API's auth failures come back as 403, never 401 |
| `Doclift::NotFoundError` | 404 |
| `Doclift::ConflictError` | 409 — a workflow write while the builder's edit lock is held |
| `Doclift::ValidationError` | 422; `#invalid_variables` carries the fillable-form variable refusals |
| `Doclift::ServerError` | 500–599 |
| `Doclift::ApiError` | any other non-2xx status |

Every `ApiError` exposes `#status`, `#message` (normalised from the API's `error` string or `errors` array — messages are mostly French, relayed as-is) and `#details` (the parsed body, where extras like a publication refusal's `anomalies` live).

The gem never retries: a create is not idempotent (the API has no idempotency key), so replays belong to the caller's job layer where the business context is known.

## Testing an application that embeds this gem

The gem memoizes a global configuration and client. Reset them around examples that touch either:

```ruby
RSpec.configure do |config|
  config.before { Doclift.reset! }
  config.after { Doclift.reset! }
end
```

Requests go through `net/http`, so WebMock stubs them directly:

```ruby
stub_request(:post, "https://app.doclift.io/api/v1/document_requests")
  .to_return(status: 200, body: {id: 991, documents_generations: [...]}.to_json)
```

## Development

`bin/setup` installs the dependencies and runs the suite. `bin/console` opens IRB with the gem loaded and deliberately configures nothing. The suite enforces 100% line and branch coverage.

## Releasing

The gem lives on GitHub only, so a release is a tag:

1. Bump `Doclift::VERSION` in `lib/doclift/version.rb`.
2. Describe the release in `CHANGELOG.md`.
3. Commit, then `git tag vX.Y.Z && git push origin master --tags`.

Treat a pushed tag as immutable: moving it changes what a fresh `bundle install` resolves without changing any lockfile.
