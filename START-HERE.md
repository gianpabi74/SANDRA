# SANDRA — Start Here

Repository ufficiale: https://github.com/gianpabi74/SANDRA

Branch autorevole: `main`

Stato aggiornato: `2026-07-22T14:08:59Z`

## Ordine di lettura

1. [Stato canonico machine-readable](STATE.json)
2. [Baseline globale](BASELINE.md)
3. [Stato corrente](CURRENT_STATE.md)
4. [Prossimo task](NEXT_TASK.md)
5. [Roadmap corrente](docs/roadmap/ROADMAP.md)
6. Journal corrente: `journal/2026/07/RB-000061AR-20260722T140859Z-b9afd4ec.md`

## Regole

- GitHub è la fonte autorevole dopo una RunBook conclusa in PASS.
- `STATE.json` è la fonte viva canonica.
- I documenti vivi descrivono solo lo stato corrente.
- I Journal sono storia immutabile.
- SANDRA è deterministica e non usa AI decisionale.
- Non cambiare architettura durante un audit.
- Non introdurre nuovi layer senza un requisito concreto.
- Seguire esattamente il gate dichiarato in `NEXT_TASK.md`.

## Stato sintetico

- Core: stabile.
- PVE: inventario e topologia.
- PBS: provider read-only operativo.
- Windows: provider `1.7.0` congelato.
- Linux: provider `1.1.0`, Get/Test certificati.
- Prossimo gate: `RB-000062`, baseline read-only dei servizi Linux.
