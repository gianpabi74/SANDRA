# Provider Windows — Baseline 1.7.0

## Stato

Baseline funzionale ricertificata e congelata con RB-000054.

## Componenti

- `provider.sh`: orchestrazione;
- `get.py`: acquisizione dello stato;
- `test.py`: calcolo offline del delta;
- `set.py`: approvazione, validazione e ciclo Set;
- `transport.py`: WinRM, PyPSRP e invocazione DSC.

## Capability supportate

### WindowsService

- Desired supportato: `Running`;
- risorsa DSC: `Service`;
- modulo: `PSDesiredStateConfiguration`;
- sequenza: Test, eventuale Set, Test finale;
- servizio protetto: `WinRM`.

### WindowsFeature

- Desired supportato: `Present`;
- risorsa DSC: `WindowsFeature`;
- modulo: `PSDesiredStateConfiguration`;
- sequenza: Test, eventuale Set, Test finale;
- rimozione feature non supportata;
- riavvio automatico non consentito.

## Contratto

- Get produce lo stato corrente;
- Test produce il delta;
- Set accetta esclusivamente un delta identico all'approvazione;
- nessuna modifica con delta vuoto;
- successo soltanto con Test finale conforme;
- il RefreshMode dell'LCM non viene modificato;
- le credenziali non vengono registrate.

## Ricertificazione

- sintassi Bash: PASS;
- compilazione Python: PASS;
- source/runtime: identici;
- isolamento trasporto: PASS;
- fixture combinata Service/Feature: PASS;
- WINSRV01: PASS;
- WINSRV02: PASS;
- SERVICESRV: PASS;
- modifiche Windows durante la ricertificazione: nessuna.

## Stato operativo

Il provider Windows entra in manutenzione.

Nuove capability verranno aggiunte soltanto in presenza di un
requisito concreto.
