# ADR-003 — Trasporto interno al provider Windows

## Stato

Approvata e implementata.

## Contesto

L'audit RB-000051A non ha rilevato un executor o un trasporto
condiviso tra i provider SANDRA.

Il solo codice di comunicazione remota esistente è specifico del
provider Windows e utilizza PyPSRP, WinRM, NTLM e le locale delle
sessioni PowerShell.

## Decisione

Il trasporto PSRP rimane interno al provider Windows.

Il file `transport.py` è l'unico componente del provider Windows che:

- importa PyPSRP;
- crea `Client`;
- configura WinRM e NTLM;
- imposta locale e timeout;
- esegue PowerShell remoto;
- converte il risultato JSON.

`get.py` utilizza l'API di `transport.py`.

Il futuro Set remoto dovrà utilizzare la stessa API.

## Componenti condivisi

Non viene creato alcun executor o trasporto nel Core.

Un componente condiviso sarà valutato soltanto quando almeno due
provider presenteranno una duplicazione reale e verificata.

## Conseguenze

- nessuna astrazione prematura;
- trasporto Windows isolato e revisionabile;
- nessuna logica PyPSRP duplicata;
- nessun cambiamento al contratto esterno del provider.
