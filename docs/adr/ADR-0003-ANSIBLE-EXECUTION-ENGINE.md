# ADR-0003 — Ansible as execution engine

## Stato

Accepted as candidate; not installed in this gate.

## Decisione

Ansible Core è il candidato principale per configurazione ed esecuzione
su Linux e Windows.

SANDRA resta responsabile di:

- decisione;
- authority;
- piano;
- selezione dell'azione;
- verifica finale.

Ansible resta responsabile dell'esecuzione dei moduli e playbook approvati.

## Limiti

Check mode è una simulazione e non tutti i moduli lo supportano.
Idempotenza e rollback devono essere dimostrati per ogni capability.

## Fonti ufficiali

- https://docs.ansible.com/projects/ansible-core/2.19/playbook_guide/playbooks_intro.html
- https://docs.ansible.com/projects/ansible-core/devel/playbook_guide/playbooks_checkmode.html
