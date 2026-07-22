# Next Task

## WindowsService Set — Applicazione DSC

Il provider Windows 1.4.0 valida un delta WindowsService e lo traduce
nella risorsa Microsoft DSC `PSDesiredStateConfiguration/Service`.

Prossimo passo:

- verificare localmente la disponibilità della risorsa DSC Service;
- implementare l'invocazione remota con `Invoke-DscResource`;
- eseguire Test immediatamente prima di Set;
- applicare soltanto il delta approvato;
- ricertificare Get e Test immediatamente dopo Set;
- non eseguire modifiche se il delta è vuoto.
