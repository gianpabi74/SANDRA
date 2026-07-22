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
- contratto Microsoft DSC Get/Test/Set approvato e versionato
- Desired State Windows definito
- provider Windows 1.0.0 installato
- operazioni Microsoft DSC Get e Test certificate
- SERVICESRV conforme al profilo corrente
- delta DhcpServer acquisito per WINSRV01 e WINSRV02

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

## RB-000045A — Provider Windows

- provider Windows 1.1.0 corretto e ricertificato;
- sorgenti Python separati e leggibili;
- locale remota `it-IT` esplicita;
- Get e Test completati sulle tre VM;
- eventuali delta conservati come risultato operativo.
- WINSRV01: Desired State `FALSE`, delta `1`
- WINSRV02: Desired State `FALSE`, delta `1`
- SERVICESRV: Desired State `FALSE`, delta `1`
## RB-000046

- baseline certificata completata;
- prossimo obiettivo: cultura per modulo.

## RB-000047R — Windows module locale

- provider Windows 1.2.0 certificato;
- `SMBShare` gestito con locale `en-US`;
- `DhcpServer` gestito con locale `it-IT`;
- Get e Test conformi sulle tre VM;
- nessuna modifica ai sistemi Windows.

## RB-000048C — Windows Set contract

- provider Windows 1.3.0 certificato;
- scheletro Set installato;
- validazione del delta certificata;
- validazione dell'approvazione certificata;
- nessuna capability modificativa ancora attiva;
- prossima fase: una singola risorsa Set per RB.

## RB-000049 — WindowsService Set

- contratto WindowsService implementato;
- mapping alla risorsa Microsoft DSC Service certificato;
- applicazione remota ancora disabilitata;
- prossimo passo: invocazione DSC controllata e ricertificazione.

## RB-000049R — Provider Windows 1.4.0

- incoerenza delle versioni corretta;
- tutti i componenti del provider dichiarano `1.4.0`;
- baseline pronta per l’implementazione remota DSC `Test → Set → Test`.
