# Trust SSH SANDRA verso target Linux

## Perimetro

La trust SSH riguarda esclusivamente:

- PBS;
- TRANSMISSION;
- PIHOLE;
- PIHOLE2;
- PLEX;
- NAVIDROME;
- SERVARR;
- PASSBOLT;
- NGINX.

Sono esplicitamente esclusi:

- hypervisor PVE;
- nodo SANDRA;
- server Windows.

## Identità

- tipo: ED25519;
- fingerprint: `SHA256:nIzmu6lgD8HXhPaRGbwzAEDw3fSRCvv8W7nDu/yVcfM`;
- chiave privata: `/opt/sandra/secrets/ssh/id_ed25519`;
- chiave pubblica: `/opt/sandra/secrets/ssh/id_ed25519.pub`;
- known_hosts: `/opt/sandra/secrets/ssh/known_hosts`.

La chiave privata resta esclusivamente su SANDRA.

## Verifica

Per ogni target:

1. accesso iniziale tramite password;
2. lettura della host key ED25519 locale;
3. confronto con il risultato di `ssh-keyscan`;
4. registrazione nel known_hosts persistente;
5. distribuzione idempotente della sola chiave pubblica;
6. verifica dell'accesso root tramite chiave.

## Vincoli

- nessuna chiave privata copiata;
- nessuna password registrata;
- nessuna modifica applicativa ai target;
- nessuna modifica a PVE o Windows.
