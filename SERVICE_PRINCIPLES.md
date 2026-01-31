# Service Principles

## 1. Local-Cloud Parity

Every service must run locally and in the cloud with no code changes. Environment-specific configuration is injected, never hardcoded. If it can't run on a developer's machine, it's not shippable.

## 2. Secure by Default

Nothing is accessible unless explicitly exposed. Static files, routes, and endpoints are denied by default. Access must be deliberately declared — if a developer forgets to configure something, the result is a 403, not a leak.

## 3. Coherent REST API

The REST API must stand on its own as a complete, consistent interface. Resource naming, status codes, pagination, and error responses follow uniform conventions. A consumer should be able to navigate the API without out-of-band knowledge.

## 4. Collision-Aware Storage

All storage operations — writes, updates, deletes — must anticipate conflicts and failures. Use conditional writes, idempotency keys, or versioning as appropriate. Never assume an operation will succeed or that you are the only writer.

## 5. Structured Error Handling

Every error returned to a caller must be a deliberate choice. Components explicitly select and throw a specific HTTP error with a structured body. Any error that is *not* explicitly chosen becomes a 500, is logged, and represents a bug the developer must investigate and resolve.
