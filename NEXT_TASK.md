# Next Task

## WindowsService — Set remoto DSC

Il provider Windows 1.5.0 dispone di un trasporto PSRP interno e
certificato.

Prossimo passo:

- usare `transport.py` nel percorso Set;
- ricevere esclusivamente operazioni validate da `set.py`;
- eseguire `Invoke-DscResource -Method Test`;
- chiamare `Set` soltanto con `InDesiredState=False`;
- ripetere `Test` dopo Set;
- non modificare il RefreshMode dell'LCM;
- applicare esclusivamente delta approvati.
