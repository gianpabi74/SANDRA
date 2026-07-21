# SANDRA — Roadmap

## Completato

### Foundation
- Core operativo
- Knowledge versionata con Git
- evidenze e artefatti esportati
- scheletro top-level canonico creato
- Costituzione presente

### PVE
- accesso SSH certificato
- provider PVE operativo
- versione, nodi, risorse, VM, container e storage osservabili
- policy PVE presente
- validator PVE presente
- execute generico presente
- start safe-path certificato
- habitat PVE nel percorso canonico

### PBS
- host identificato
- chiave SSH dedicata installata
- accesso root senza password certificato
- CLI locale PBS certificata
- capability read-only verificate
- provider PBS read-only operativo
- sorgente provider PBS versionata

### Windows — trasporto
- ambiente Python isolato installato
- PyPSRP installato e certificato
- requisiti e dipendenze versionati
- WinRM certificato su WINSRV01
- WinRM certificato su WINSRV02
- WinRM certificato su SERVICESRV
- identità, sistema operativo, dominio, ruoli e feature osservabili
- audit approfondito read-only completato
- AD DS, replica, DNS e DHCP osservati sui Domain Controller
- IIS, AD CS, servizi e condivisioni osservati su SERVICESRV

## Ordine di sviluppo

1. Windows
2. Linux
3. Docker
4. Verify
5. Remember
6. Decision
7. Report

## Vincoli permanenti

- nessuna nuova directory top-level
- nessuna assunzione non verificata
- nessun mega-refactoring
- una responsabilità per ogni cambiamento
- Core e Knowledge importati in ogni Bash
