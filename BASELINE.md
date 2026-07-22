# SANDRA — Baseline globale certificata

Aggiornato: `2026-07-22T14:08:59Z`

Repository: https://github.com/gianpabi74/SANDRA

Branch: `main`

RunBook corrente: `RB-000061AR`

Journal corrente: `journal/2026/07/RB-000061AR-20260722T140859Z-b9afd4ec.md`

## Principi permanenti

- motore deterministico;
- nessuna AI decisionale;
- un solo owner per responsabilità;
- provider indipendenti;
- nessun secret nel repository;
- nessuna complessità senza valore operativo;
- stato corrente nei documenti vivi;
- cronologia nei Journal immutabili.

## Provider

### PVE

- versione `1.7.0`;
- operativo per inventario e topologia;
- non governa lo stato interno di Linux.

### PBS

- versione `1.0.0`;
- read-only operativo.

### Windows

- versione `1.7.0`;
- stato congelato e in manutenzione;
- Get/Test/Approval/Set certificati;
- WindowsService e WindowsFeature certificati;
- baseline: `docs/providers/windows/BASELINE-1.7.0.md`.

### Linux

- versione `1.1.0`;
- trasporto OpenSSH con chiave pubblica;
- host key validation obbligatoria;
- Get remoto certificato;
- Test offline certificato;
- Set assente;
- nove target Linux certificati;
- PVE, SANDRA e Windows esclusi dal perimetro Linux.

## Prossimo gate

`RB-000062 — Baseline certificata dei servizi Linux`

Il gate è esclusivamente read-only. LinuxService non può essere
implementato prima dell'approvazione della baseline dei servizi governabili.
