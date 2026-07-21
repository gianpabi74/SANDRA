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

Certificate in sola lettura:

- WINSRV01 — `192.168.1.251`
- WINSRV02 — `192.168.1.203`
- SERVICESRV — `192.168.1.204`

Configurazione certificata:

- trasporto WinRM HTTP
- porta `5985`
- autenticazione NTLM
- cifratura messaggio `always`
- identità remota verificata
- servizio WinRM in esecuzione

Le credenziali non sono registrate nella Knowledge.
