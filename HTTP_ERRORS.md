# HTTP Error Handling

1. HTTP status codes must be standard. Use an atypical code only when no standard code fits — for example, don't use 204 unless 200 is unacceptable.

2. 2xx and 3xx responses may carry content freely.

3. 4xx and 5xx responses MUST carry a standardized JSON payload with these fields:
   - `statusCode` — the HTTP status code (integer).
   - `subCode` — a stable error ID (e.g. `ACCOUNT_ALREADY_EXISTS`), or null if none applies.
   - `message` — a map of language identifier to localized message. The map is always present; in the non-localized case it contains a single `en` entry.

4. The payload defined in rule 3 is the ONLY data that may appear in a 4xx or 5xx response. Everything else — stack traces, internal request/trace IDs, database IDs, exception types, auxiliary objects — MUST be assumed sensitive and MUST NOT be disclosed. Two narrow carveouts:
   - **Mandatory protocol constraints.** When an external protocol the service implements (e.g. OAuth 2.0, MCP) dictates a specific error response shape, that shape supersedes rule 3 for those endpoints.
   - **Opt-in holistic error contracts.** When the application has explicitly defined a richer client/service contract for a specific error class (e.g. an HTTP 409 conflict that returns the conflicting resource so the client can resolve it), the additional fields are permitted. The opt-in must be explicit and documented; it is not a license to attach ad-hoc context.

5. A component MAY generate an HTTP status code only if it has access to the request context — enough to also populate the stable ID required by rule 3.

6. A component without request context MUST NOT generate an HTTP status code. It throws a generic exception instead.

7. Request-aware components MAY catch generic exceptions and convert them to HTTP errors, but only when they actually understand the failure. Otherwise the exception propagates unchanged.

8. The top-level handler MUST convert any non-HTTP exception that reaches it into a generic 500 response, AND log the original exception (including stack trace) to the server-side telemetry sink before responding. Reaching this path is a bug and must be fixed at the source.
