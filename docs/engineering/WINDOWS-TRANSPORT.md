# Trasporto Windows

## Stato

Runtime locale PyPSRP certificato.

## Percorsi

- ambiente virtuale: `/opt/sandra/provider/windows/.venv`
- requisiti diretti: `src/providers/windows/requirements.txt`
- dipendenze risolte: `src/providers/windows/requirements.lock`

## Versioni certificate

- Python base: `3.13.7`
- PyPSRP: `0.9.1`

## Scopo

Il runtime fornisce a Windows il client locale per PSRP e WinRM.
Non contiene credenziali e non prende decisioni.

## Stato delle connessioni

Le connessioni a WINSRV01, WINSRV02 e SERVICESRV non sono ancora certificate.
La certificazione del trasporto remoto è il prossimo passo.
