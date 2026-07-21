# Next Task

## Windows Provider Set

Il provider Windows 1.2.0 implementa Get e Test.

Locale moduli certificata:

- default: it-IT;
- DhcpServer: it-IT;
- SMBShare: en-US.

WINSRV01, WINSRV02 e SERVICESRV sono conformi al Desired State corrente.

Prossimo passo:

- definire Microsoft DSC Set;
- Set deve ricevere esclusivamente un delta approvato;
- Test deve precedere sempre Set;
- nessuna decisione deve risiedere nel provider;
- ogni modifica deve essere documentata e certificata.
