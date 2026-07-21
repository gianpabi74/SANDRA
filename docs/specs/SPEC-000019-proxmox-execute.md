# SPEC-000019 — Proxmox Execute

## Stato

Certified PASS.

## Percorso

`/opt/sandra/execute/proxmox_execute.sh`

## Versione

`1.0.0`

## Funzione

`execute_proxmox DECISION_FILE`

## Responsabilità

`execute`:

- riceve una decisione già prodotta;
- accetta esclusivamente `ALLOW`;
- inoltra l'azione al provider;
- restituisce l'esito tecnico.

## Divieti

`execute` non:

- sceglie l'oggetto;
- sceglie l'azione;
- interpreta la policy;
- modifica la decisione;
- decide tempi o priorità.

## Source safety

Il modulo:

- non contiene dichiarazioni top-level `readonly`;
- può essere caricato più volte nello stesso processo;
- non esegue azioni durante il caricamento.

## Azioni implementate

- `start`
