# Domain

Modello di dominio indipendente da runtime, interfacce e tecnologie concrete.

Il dominio contiene tipi, contratti, errori e validazione deterministica.

Sono vietate dipendenze verso:

- provider e adapter concreti;
- API di prodotti;
- configurazioni dell'Habitat;
- credenziali;
- servizi runtime;
- interfacce utente.
