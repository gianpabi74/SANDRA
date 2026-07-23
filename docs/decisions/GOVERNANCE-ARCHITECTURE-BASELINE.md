# Governance Architecture Baseline

## Missione

SANDRA è un controller deterministico dell'ambiente gestito.

Mantiene l'ambiente entro i limiti dichiarati attraverso un ciclo continuo:

1. osservazione;
2. riconciliazione;
3. valutazione delle policy;
4. pianificazione;
5. esecuzione;
6. verifica;
7. registrazione.

## Modelli adottati

- Kubernetes Controller Pattern per il reconciliation loop.
- Open Policy Agent come candidato policy decision point.
- Ansible Core come candidato execution engine Linux e Windows.
- API ufficiali come interfaccia primaria delle piattaforme.
- Nmap come discovery source non autorevole.
- Prometheus come fonte di metriche e Alertmanager come event router.
- Git e Knowledge per stato progettuale, policy, ADR e continuità.
- Database operativo separato dalla Knowledge; scelta differita al modello dati.

## Separazione delle responsabilità

- Controller: riconcilia stato osservato e stato governato.
- Policy decision point: decide authority e limiti.
- Planner: produce un piano immutabile.
- Executor: usa strumenti maturi.
- Verifier: verifica indipendentemente.
- Repository operativo: conserva oggetti, evidenze e transazioni.
- Knowledge: conserva architettura, policy, decisioni e continuità.

## Autonomia

L'uomo approva le policy, non le singole azioni già delegate.

Esiti ammessi:

- autonomous;
- conditional_autonomous;
- escalate;
- denied.

La criticità dell'oggetto aumenta precondizioni, limiti e verifiche, ma non
impone automaticamente il consenso umano.

## Vincoli

- nessuna AI decisionale;
- nessuna tecnologia hardcoded nel dominio;
- nessuna correzione ad intuito;
- nessuna capability senza evidenze, policy e verifica;
- nessun nuovo strumento prima della relativa decisione architetturale;
- interfaccia headless prima della futura UI.
