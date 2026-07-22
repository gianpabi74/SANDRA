# Next Task

## Provider Linux — Trasporto SSH con chiave

La trust SSH è certificata sui nove target Linux.

Prossimo passo:

- aggiornare `transport.py`;
- usare `/opt/sandra/secrets/ssh/id_ed25519`;
- usare `/opt/sandra/secrets/ssh/known_hosts`;
- imporre `StrictHostKeyChecking=yes`;
- rimuovere la password dai normali flussi Get;
- ricertificare Get/Test sui nove target;
- non coinvolgere PVE, SANDRA o Windows.
