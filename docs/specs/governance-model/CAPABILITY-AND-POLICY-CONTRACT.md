# Capability and Policy Contract

## Stato

Canonical V1.

## Capability

Una Capability è un contratto astratto, versionato e indipendente dalla
tecnologia che lo implementa.

Una Capability definisce:

- identificatore;
- versione;
- scopo;
- input;
- output;
- precondizioni;
- postcondizioni;
- livello di rischio;
- reversibilità;
- strategia di verifica;
- strategia di recovery;
- compatibilità con gli adapter.

Una Capability non contiene:

- hostname;
- indirizzi IP;
- VMID;
- nomi di prodotti;
- policy specifiche di un singolo oggetto;
- credenziali;
- comandi concreti dell'implementazione.

## Policy

Una Policy assegna authority a una Capability per oggetti selezionati mediante
classificazioni, ruoli, protection profile e condizioni osservate.

La Policy produce esclusivamente uno dei seguenti risultati:

- `autonomous`
- `conditional_autonomous`
- `escalate`
- `denied`

`escalate` non è un consenso preventivo ordinario. Indica che le regole
disponibili non consentono una decisione univoca.

`denied` non può essere trasformato in `autonomous` mediante un'approvazione
occasionale. Richiede una modifica esplicita e versionata della Policy.

## Policy Decision

Una Policy Decision deve registrare:

- policy valutate;
- revisione delle policy;
- Capability richiesta;
- oggetto interessato;
- evidenze considerate;
- risultato;
- condizioni obbligatorie;
- limiti;
- motivazioni;
- timestamp;
- decision identifier.

## Execution Plan

Un Execution Plan è immutabile dopo la creazione.

Contiene:

- riferimenti alla decisione;
- target;
- Capability;
- adapter selezionato;
- precheck;
- azioni;
- postcheck;
- recovery;
- limiti;
- scadenza;
- hash del piano.

Il piano non può essere eseguito se:

- la decisione è scaduta;
- lo stato osservato è cambiato oltre i limiti dichiarati;
- l'adapter non implementa la Capability nella versione richiesta;
- una precondizione è falsa;
- le evidenze sono conflittuali;
- il piano non è verificabile.

## Autonomia

L'autonomia viene concessa alla combinazione:

- Capability;
- versione Capability;
- adapter;
- versione adapter;
- selettore degli oggetti;
- limiti;
- condizioni;
- metodo di verifica.

Non viene concessa genericamente all'intero runtime.

## Progressive Trust

Stati ammessi:

- `disabled`
- `observe_only`
- `recommend`
- `approval_required`
- `autonomous_canary`
- `autonomous`
- `suspended`

Il passaggio a un livello superiore richiede evidenze registrate.

Errori ripetuti, rollback o mismatch di verifica possono sospendere
automaticamente la Capability.

## Principi

- la Policy decide;
- l'enforcement applica;
- l'adapter traduce;
- lo strumento opera;
- il verifier dimostra il risultato;
- ogni azione autonoma resta entro budget espliciti;
- nessun oggetto concreto viene codificato nella Capability;
- nessuna decisione viene incorporata nell'adapter.
