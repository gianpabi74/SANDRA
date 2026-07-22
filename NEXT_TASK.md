# Next Task

## Chiusura provider Windows

Il provider Windows 1.7.0 supporta:

- WindowsService:
  - Get;
  - Test;
  - approvazione;
  - DSC Test/Set/Test.

- WindowsFeature:
  - Get;
  - Test;
  - approvazione;
  - DSC Test/Set/Test.

Le tre VM sono conformi e non hanno richiesto modifiche.

Prossimo passo:

- ricertificazione finale del provider Windows;
- verifica integrità Knowledge;
- congelamento della baseline Windows;
- successiva integrazione del secret store;
- poi avvio del provider Linux.
