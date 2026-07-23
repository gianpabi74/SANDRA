# Object and Evidence Model

## Stato

Canonical V1.

## Modelli di riferimento

- Kubernetes API conventions:
  `apiVersion`, `kind`, `metadata`, `spec`, `status`.
- OpenTelemetry semantic conventions:
  attributi coerenti e portabili per risorse e osservazioni.
- JSON Schema Draft 2020-12:
  validazione deterministica dei documenti.
- CloudEvents:
  riferimento futuro per l'envelope degli eventi operativi.

## Managed Object

Un Managed Object rappresenta un'entità persistente dell'ambiente gestito.

Campi obbligatori:

- `apiVersion`
- `kind`
- `metadata`
- `spec`
- `status`

### metadata

Contiene identità amministrativa stabile:

- `id`: identificatore immutabile generato dal sistema;
- `name`: nome leggibile;
- `labels`: classificazioni usate dalle policy;
- `annotations`: metadati non selettivi;
- `createdAt`;
- `updatedAt`.

### spec

Contiene stato governato e dichiarazioni autorizzate:

- classificazioni;
- ruoli;
- protection profile;
- identità dichiarate;
- capability richieste;
- policy binding.

### status

Contiene stato osservato e derivato:

- lifecycle phase;
- technology identification;
- capability disponibili;
- condizioni;
- latest observation;
- reconciliation revision.

`spec` non viene popolato automaticamente da una singola osservazione.

`status` non modifica autonomamente `spec`.

## Observation

Una Observation è un fatto raccolto da una fonte.

Non contiene decisioni.

Proprietà minime:

- soggetto osservato;
- fonte;
- istante;
- attributo;
- valore;
- unità, se applicabile;
- qualità;
- riferimento al dato grezzo.

## Evidence

Evidence collega una o più osservazioni a:

- provenienza;
- integrità;
- metodo di acquisizione;
- timestamp;
- classificazione di autorevolezza.

Livelli iniziali:

- `authoritative`
- `corroborated`
- `candidate`
- `conflicting`

Nmap produce normalmente evidenza `candidate`.

Un'API ufficiale autenticata può produrre evidenza `authoritative`
nel proprio ambito documentato.

## Relationship

Una Relationship collega due Managed Object.

Tipi iniziali:

- `hostedOn`
- `dependsOn`
- `managedBy`
- `protectedBy`
- `backedUpBy`
- `resolvesThrough`
- `peerOf`
- `provides`
- `consumes`

Le relazioni devono avere evidenze e validità temporale.

## Regole

- nessuna identità viene confermata da un solo segnale debole;
- indirizzo IP, hostname e MAC non sono identificatori universali;
- dati osservati e stato governato restano separati;
- ogni modifica autonoma deve riferirsi a un object ID stabile;
- ogni decisione deve indicare le evidenze utilizzate;
- conflitti fra fonti impediscono l'azione finché la policy non li risolve;
- nomi di prodotto non entrano nel nucleo del dominio.
