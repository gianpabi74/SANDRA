# SANDRA — Roadmap corrente

Aggiornato: `2026-07-22T14:08:59Z`

La cronologia completa è nei Journal. Questa roadmap mostra soltanto stato e
gate correnti.

## Completato

- Core stabile e Knowledge/Git operativi.
- Provider PVE `1.7.0`: inventario e topologia.
- Provider PBS `1.0.0`: read-only operativo.
- Provider Windows `1.7.0`: congelato e in manutenzione.
- Provider Linux `1.1.0`: trust SSH, Get e Test certificati.
- Continuità GitHub: `STATE.json`, documenti vivi e validazione obbligatoria.

## In corso

1. `RB-000062` — baseline read-only dei servizi systemd.
2. `RB-000063` — LinuxService Get/Test sui servizi approvati.
3. `RB-000064` — LinuxService Set con approvazione e verifica finale.
4. `RB-000065` — ricertificazione e congelamento baseline Linux.

## Fuori perimetro corrente

- Package management;
- File management;
- utenti e gruppi;
- firewall;
- cron;
- gestione generica fstab;
- nuove capability Windows;
- Secret Manager trasversale.

## Vincoli permanenti

- nessuna assunzione non verificata;
- nessun mega-refactoring;
- provider indipendenti;
- documenti vivi riscritti integralmente;
- Journal immutabili;
- GitHub sincronizzato prima della chiusura della RB.
