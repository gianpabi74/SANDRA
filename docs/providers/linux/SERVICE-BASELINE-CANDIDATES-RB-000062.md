# RB-000062 — Inventario servizi applicativi Linux

> Stato: `INVENTORY CERTIFIED`  
> Modalità: `REMOTE READ-ONLY`

`RB-000062` ha osservato e classificato i servizi presenti sui
target Linux.

## Risultato certificato

- host osservati: `9`;
- unità osservate: `1095`;
- unità failed: `2`;
- servizi applicativi candidati: `9`;
- errori di raccolta: `0`;
- modifiche remote: `NESSUNA`.

## Passo corrente

SANDRA deve associare automaticamente ogni oggetto applicativo
alla relativa unità systemd.

L’associazione usa esclusivamente:

- nome dell’oggetto;
- profilo del target;
- inventario systemd certificato.

I risultati ammessi sono:

- `RESOLVED`;
- `NOT_FOUND`;
- `AMBIGUOUS`.

Solo `RESOLVED` permette di proseguire.

`NOT_FOUND` e `AMBIGUOUS` arrestano il flusso senza effettuare
modifiche.

Non è richiesta alcuna approvazione manuale dei nomi delle unità
systemd.
