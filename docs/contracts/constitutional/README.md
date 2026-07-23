# SANDRA Constitutional Operational Contracts V1

Questi contratti definiscono le invarianti operative sulle quali verranno
costruiti Application Layer, controller e adapter.

## Contratti

1. Resource Lifecycle Contract
2. Evidence Authority Contract
3. Reconciliation Concurrency Contract
4. Execution Safety Contract

## Principio

I contratti sono indipendenti da prodotti e tecnologie.

Proxmox, VMware, Linux, Windows, PBS, OpenVAS, OPA, SSH e qualsiasi futura
tecnologia devono rispettare questi contratti tramite porte e adapter.

## Effetto

Nessun controller o adapter può:

- promuovere automaticamente una scoperta a verità autorevole;
- agire su una generazione obsoleta;
- eseguire due mutazioni concorrenti incompatibili;
- eseguire senza decisione, precondizioni e verifica;
- considerare il successo del comando come prova del risultato;
- superare i limiti di autonomia delegati dalle policy;
- compromettere la sopravvivenza dell'Habitat per ottimizzare un servizio.
