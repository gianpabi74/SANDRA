# Next Task

## Provider Linux — Capability LinuxService

Il provider Linux 1.1.0 dispone di:

- trasporto SSH con chiave;
- host key validation;
- Get remoto;
- Test offline;
- nove target certificati.

Prossimo passo:

- definire i servizi desiderati per ciascun profilo;
- estendere Get con stato strutturato delle unità dichiarate;
- estendere Test con delta `LinuxService`;
- mantenere Set assente fino alla ricertificazione Get/Test;
- non coinvolgere PVE, SANDRA o Windows.
