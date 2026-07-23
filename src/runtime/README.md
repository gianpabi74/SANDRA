# Runtime source

Questa directory contiene il codice Python indipendente dalle tecnologie
specifiche dell'ambiente gestito.

Il package `governance` implementa esclusivamente contratti del dominio e
del ciclo di governo.

Non deve importare:

- provider o adapter specifici;
- API Proxmox, VMware, Windows o Linux;
- credenziali;
- configurazioni concrete dell'Habitat.
