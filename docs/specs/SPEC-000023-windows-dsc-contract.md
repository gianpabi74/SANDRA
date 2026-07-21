# SPEC-000023 — Windows DSC Contract

## Stato

APPROVATO.

## Fonte normativa

Il contratto deriva esclusivamente dalla documentazione ufficiale Microsoft DSC.

Fonti:

- `https://learn.microsoft.com/powershell/dsc/concepts/resources/operations`
- `https://learn.microsoft.com/powershell/dsc/concepts/get-test-set`
- `https://learn.microsoft.com/powershell/dsc/getting-started/invoking-dsc-resources`
- `https://learn.microsoft.com/powershell/dsc/reference/psdscresources/resources/script/script`
- `https://learn.microsoft.com/powershell/module/servermanager/get-windowsfeature`

## Operazioni

### Get

Recupera lo stato corrente della risorsa.
Non modifica il sistema.

### Test

Confronta lo stato corrente con lo stato desiderato.
Restituisce se la risorsa è conforme.
Non modifica il sistema.

### Set

Applica lo stato desiderato.
Deve essere invocato soltanto quando Test indica non conformità.
Deve essere implementato in modo idempotente.

## Vincoli

- usare risorse DSC definite quando disponibili;
- evitare la risorsa Script quando esiste una risorsa specifica;
- nessuna decisione nel provider;
- nessuna modifica durante Get;
- nessuna modifica durante Test;
- Set applica esclusivamente lo stato desiderato ricevuto;
- gli eventuali riavvii richiesti devono essere dichiarati nel risultato;
- ruoli e feature Windows sono osservati tramite ServerManager;
- le credenziali non entrano nella Knowledge.

## Applicazione iniziale

- WINSRV01: profilo Domain Controller;
- WINSRV02: profilo Domain Controller;
- SERVICESRV: profilo Services Server.

I profili saranno definiti nel prossimo passo usando esclusivamente:

- ruoli realmente osservati;
- feature Windows ufficiali;
- moduli PowerShell Microsoft;
- servizi richiesti dai ruoli Microsoft.
