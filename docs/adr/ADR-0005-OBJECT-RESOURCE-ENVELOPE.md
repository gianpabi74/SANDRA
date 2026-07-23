# ADR-0005 — Object resource envelope

## Stato

Accepted.

## Decisione

Le risorse canoniche usano:

- `apiVersion`
- `kind`
- `metadata`
- `spec`
- `status`

La separazione deriva dalle Kubernetes API conventions.

OpenTelemetry semantic conventions orientano il vocabolario degli attributi
osservati, senza obbligare SANDRA ad adottare l'intero stack OpenTelemetry.

JSON Schema Draft 2020-12 definisce i contratti machine-readable.

## Fonti ufficiali

- https://kubernetes.io/docs/concepts/overview/working-with-objects/
- https://kubernetes.io/docs/reference/using-api/api-concepts/
- https://opentelemetry.io/docs/concepts/semantic-conventions/
- https://json-schema.org/draft/2020-12
