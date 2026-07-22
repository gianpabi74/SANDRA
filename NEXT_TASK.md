# Next Task

## WindowsService — Applicazione remota DSC

Il provider Windows 1.4.0 è coerente in tutti i componenti.

Sono certificati:

- risorsa DSC `Service`;
- modulo `PSDesiredStateConfiguration` 1.1;
- `Invoke-DscResource Get`;
- `Invoke-DscResource Test`;
- forma del risultato `InDesiredState`;
- LCM in `RefreshMode=Push`.

Prossimo passo:

- integrare in `provider_set` la connessione WinRM;
- eseguire DSC Test immediatamente prima di Set;
- eseguire Set solo con `InDesiredState=False`;
- ripetere DSC Test dopo Set;
- applicare esclusivamente un delta WindowsService approvato;
- non cambiare il RefreshMode dell’LCM.
