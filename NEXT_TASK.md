# Next Task

## RB-000062 — Baseline certificata dei servizi Linux

### Tipo

Audit remoto read-only.

### Target

- PBS
- TRANSMISSION
- PIHOLE
- PIHOLE2
- PLEX
- NAVIDROME
- SERVARR
- PASSBOLT
- NGINX

Sono esclusi PVE, SANDRA e i sistemi Windows.

### Obiettivo

1. raccogliere le unità systemd in formato strutturato;
2. acquisire nome, descrizione, LoadState, ActiveState, SubState,
   UnitFileState e FragmentPath;
3. distinguere servizi applicativi, infrastrutturali e del sistema operativo;
4. produrre un inventario JSON per host;
5. proporre esclusivamente i servizi candidati alla gestione;
6. attendere approvazione umana della baseline.

### Divieti

- nessuna modifica ai target;
- nessun start, stop, enable o disable;
- nessuna modifica ai profili;
- nessuna implementazione LinuxService;
- nessun coinvolgimento di PVE, SANDRA o Windows.

### Gate successivo

Solo dopo approvazione: `RB-000063 — LinuxService Get/Test`.
