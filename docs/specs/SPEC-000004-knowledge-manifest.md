# SPEC-000004 — Knowledge Manifest

## Stato

Frozen.

## Percorso canonico

`/opt/sandra/knowledge/manifest/KNOWLEDGE_MANIFEST.json`

## Scopo

Il manifest definisce le sezioni canoniche, gli owner, l'ordine di
lettura, i source root e i contenuti vietati della Knowledge.

I singoli documenti Markdown non vengono elencati nel manifest:
vengono scoperti automaticamente nella cartella canonica pertinente.

## Formato

JSON, validato tramite la libreria standard Python 3.

Non sono ammesse dipendenze YAML o parser Bash interni.
