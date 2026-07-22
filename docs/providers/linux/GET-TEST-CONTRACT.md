# Provider Linux 1.0.0 — Contratto Get/Test

## Perimetro

Il provider governa un sistema Linux raggiungibile tramite SSH.

Il provider non determina se il target è:

- VM;
- LXC;
- host fisico;
- nodo Proxmox.

La topologia appartiene al provider PVE.

## Get

`provider_get` riceve:

1. nome atteso;
2. indirizzo IP;
3. profilo;
4. utente SSH, opzionale.

La password viene letta da standard input e non viene registrata.

Lo stato raccoglie:

- identità;
- sistema operativo;
- kernel e architettura;
- PID 1;
- virtualizzazione;
- package manager;
- stato systemd;
- unità fallite tramite output JSON e `systemctl show`;
- `/etc/fstab`;
- filesystem root.

## Test

`provider_test` è completamente offline.

Confronta lo stato corrente con invarianti dichiarati nei profili.

## Set

Non implementato nella versione 1.0.0.

## Vincoli

- nessuna modifica remota;
- nessun parsing di tabelle destinate all’operatore;
- trasporto SSH isolato in `transport.py`;
- nessuna dipendenza Python esterna.

## Autenticazione SSH con chiave — versione 1.1.0

Il provider Linux usa esclusivamente:

- chiave privata:
  `/opt/sandra/secrets/ssh/id_ed25519`;
- known_hosts:
  `/opt/sandra/secrets/ssh/known_hosts`;
- autenticazione `publickey`;
- `StrictHostKeyChecking=yes`;
- `IdentitiesOnly=yes`;
- `PasswordAuthentication=no`;
- `KbdInteractiveAuthentication=no`.

`provider_get` non riceve e non legge password.

Il trasporto fallisce se la chiave privata o il known_hosts
persistente non sono disponibili.
