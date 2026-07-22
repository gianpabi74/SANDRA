# SANDRA — Roadmap corrente

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

Aggiornato: `2026-07-22T19:04:58Z`

## Fase corrente

`Linux provider closure`

## Gate

1. **RB-000062** — Inventario e risoluzione deterministica dei servizi Linux (`next`, `read_only`)
2. **RB-000063** — LinuxService Get/Test (`blocked`)
3. **RB-000064** — LinuxService Set (`blocked`)
4. **RB-000065** — Ricertificazione e baseline Linux (`blocked`)

## Fuori perimetro corrente

- Package management
- File management
- User and group management
- Firewall
- Cron
- Generic fstab management
- New Windows capabilities
- Cross-provider Secret Manager

## Vincoli permanenti

- motore deterministico
- nessuna AI decisionale
- un solo owner per responsabilità
- provider indipendenti
- nessun secret nel repository
- nessuna complessità senza valore operativo
- audit prima dell'implementazione
- nessun cambio di architettura senza requisito concreto
- ogni proposta supera il Gate di Necessita Ingegneristica
- identita degli oggetti basata su evidenze osservabili
- Knowledge aggiornata nella stessa transazione tecnologica

- `STATE.json` è la sorgente viva canonica.
- Le viste Markdown sono generate.
- I Journal sono immutabili.
- GitHub deve essere sincronizzato prima della chiusura della RB.
