# SPEC-000005 — Knowledge Canonical Module

## Stato

Frozen.

## Link stabile

`/opt/sandra/knowledge/knowledge.sh`

## Sorgente canonico

`/opt/sandra/knowledge/src/knowledge/knowledge.sh`

## Manifest

`/opt/sandra/knowledge/manifest/KNOWLEDGE_MANIFEST.json`

## API pubblica

- `knowledge_validate_manifest`
- `knowledge_validate`
- `knowledge_generate_index`
- `knowledge_assert_clean`
- `knowledge_commit`
- `knowledge_push`
- `knowledge_verify_remote`
- `knowledge_sync`
- `knowledge_journal_path`

## Contratto

Il modulo non contiene l'elenco dei singoli documenti.

I documenti vengono scoperti automaticamente nelle directory definite
dal manifest.

`knowledge_sync` esegue:

`validate → index → validate → commit → push → verify`

## Correzione RB-000010B1

La scansione delle chiavi private:

- ignora i link simbolici;
- considera materiale sensibile soltanto un file il cui contenuto,
  rimosso l'eventuale spazio iniziale, comincia con una intestazione
  privata riconosciuta;
- non segnala stringhe dimostrative presenti nel codice sorgente o
  nella documentazione.
