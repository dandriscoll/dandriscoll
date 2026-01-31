# Dials: Runtime Configuration System

## Overview

Dials is a runtime configuration system that allows tuning application behavior without restarts or redeployments. Dials are named, typed key-value settings stored in a persistent database document and refreshed into application memory on a configurable periodic interval.

A core design principle of Dials is that **the system must never block application execution or cause failures**. All database reads and value parsing occur in a background loop, isolated from request processing. If the database is unreachable, a stored value is malformed, or a dial is misconfigured, the system silently falls back to the last known good value (or the compiled default) and continues operating normally. No dial-related error should ever propagate to callers or degrade application availability.

## Concepts

### Dial

A dial is a single configurable setting with:

- **Name** -- A unique string identifier.
- **Description** -- A human-readable explanation of the dial's purpose.
- **Default value** -- The value used when no override has been stored in the database.
- **Current value** -- The active runtime value, initially set to the default and updated from the database on each refresh cycle.

### Supported value types

Dials support four value types: **boolean**, **integer**, **floating-point number**, and **string**. Values are stored as strings in the database and parsed to the appropriate type at load time.

### Percentage Dial

A percentage dial is a specialized integer dial (value 0-100) that supports probabilistic evaluation. It exposes an `Evaluate` operation:

- **Without context:** Returns `true` if the dial's value is greater than a random integer in [0, 99]. This produces a statistically proportional rollout (e.g., a dial set to 30 returns `true` roughly 30% of the time).
- **With a context string:** Returns `true` if the dial's value is greater than a deterministic hash of the context string, mapped to the same range. This ensures **stable results** for the same context (e.g., the same user ID always gets the same outcome for a given dial value), enabling consistent per-entity rollouts.

When the context string is null, the context-based evaluation falls back to random evaluation.

### Dial Containers

Dials are organized into **container classes** -- static groupings of related dials declared as public static fields. For example, one container might hold infrastructure-level dials (cache TTL, polling intervals) while another holds business-logic dials (feature gates, size limits). Any number of containers can be registered.

## Storage

All dial overrides are stored in a **single database document** with a well-known partition key and document ID. The document contains an array of name/value pairs, where each entry maps a dial name to its string-encoded override value.

Only dials whose values differ from defaults need to be present in the document. If a registered dial has no matching entry in the document, it retains its default value.

## Lifecycle

### 1. Registration

At application startup, the system discovers dials by reflecting over each registered container class. It enumerates all public static fields whose type is a generic dial type, reads each dial's name, and builds a name-to-instance lookup table.

### 2. Initial Load

Before the application begins serving requests, it performs a blocking synchronous load: it reads the database document and applies all stored values to the registered dials. This guarantees that dials are populated before any business logic executes.

### 3. Periodic Refresh

After the initial load, a background loop runs on a configurable interval (default: 5 minutes). On each cycle:

1. Read the dial configuration document from the database.
2. Compare the document's last-modified timestamp to the previously seen timestamp. If unchanged, skip processing.
3. For each name/value entry in the document, look up the corresponding registered dial by name.
4. Parse the string value to the dial's declared type and set the dial's current value.
5. If a stored name has no matching registered dial, emit a "dial not found" telemetry event and continue.
6. If parsing fails (type mismatch, invalid format, null value), catch the exception, emit telemetry, and leave the dial at its previous value.

### 4. On-Demand Refresh

The system supports triggering an immediate refresh outside the normal interval. This is useful after an operator manually updates the database document and wants changes applied without waiting for the next polling cycle.

### 5. Self-Referential Interval

The refresh interval is itself a dial. Changing it in the database adjusts how frequently the system polls for updates, taking effect on the next cycle.

### 6. Failsafe

If the refresh interval is set to 1 second or less (likely a misconfiguration), the system clamps it to 5 minutes to prevent excessive database reads.

## Error Handling

- **Parse failures:** If a stored value cannot be parsed to the dial's type, the exception is caught and tracked. The dial retains its previous value (or default if never successfully updated). Processing continues for remaining dials.
- **Missing dials:** If the database contains a name that does not match any registered dial, a telemetry event is emitted. No error is raised.
- **Missing document:** If the database document does not exist, a telemetry event is emitted and the dials retain their defaults.
- **Database errors:** If the database read fails entirely, the exception is caught, telemetry is emitted, and all dials retain their previous values. The next refresh cycle will retry.

## Database Initialization Tool

A CLI tool is provided to initialize and clean up the dial configuration document:

1. Read the existing document from the database (or start with an empty one).
2. Remove any entries whose names do not match currently registered dials (cleaning up stale entries from removed dials).
3. Write the cleaned document back using optimistic concurrency (ETag-based) to avoid conflicting writes.

## Telemetry

The system emits the following telemetry events:

| Event | Trigger |
|-------|---------|
| Refresh triggered | An on-demand refresh was requested |
| Update failed | The periodic update cycle encountered an unhandled error |
| Dial not found | A stored dial name has no matching registered dial |
| Empty document | The configuration document was not found in the database |
| No change | The document timestamp has not changed since the last refresh |

## Design Properties

- **Process-wide singletons:** Dial instances are static fields, so their values are shared across all threads in a process. Updates are applied in-place.
- **Eventually consistent:** Changes to the database document are picked up within one polling interval. There is no push notification mechanism.
- **Graceful degradation:** Any failure during refresh leaves dials at their last known good values. The system never crashes due to a dial misconfiguration.
- **No API surface for mutation:** Dials are read-only from the application's perspective. Operators modify dial values by editing the database document directly or via the CLI initialization tool.
- **Extensible grouping:** New dial containers can be added by creating a new static class with public static dial fields and registering it at startup.
