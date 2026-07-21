# Next Task

## Windows DSC Set

Il provider Windows 1.0.0 implementa Get e Test.

Stato osservato:

- WINSRV01: modulo DhcpServer presente ma non importabile;
- WINSRV02: modulo DhcpServer presente ma non importabile;
- SERVICESRV: conforme al Desired State corrente.

Prossimo passo:

- verificare con documentazione Microsoft la remediation del modulo DhcpServer;
- implementare Set esclusivamente per il delta certificato;
- eseguire Test prima di Set;
- ricertificare Get e Test dopo Set;
- non registrare credenziali nella Knowledge.
