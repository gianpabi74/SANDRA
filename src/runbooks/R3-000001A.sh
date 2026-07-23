#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000001A-architecture-baseline.sh"

sandra_begin \
    "R3-000001A" \
    "Register governance architecture baseline and repair Knowledge structure"

for command_name in python3 git install cp sha256sum; do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"
BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

sandra_require_file "${STATE}"
sandra_require_file "${ROOT}/manifest/KNOWLEDGE_MANIFEST.json"

install -d -m 0700 "${BACKUP_ROOT}"
cp -a -- "${STATE}" "${BACKUP_ROOT}/STATE.json.before"

# Directory già dichiarate dal manifest ma mancanti nella runtime Knowledge.
install -d -m 0755 \
    "${ROOT}/docs/decisions" \
    "${ROOT}/docs/glossary" \
    "${ROOT}/src/runbooks" \
    "${ROOT}/docs/adr"

install -m 0600 \
    "${SANDRA_RUNBOOK_SOURCE}" \
    "${RUNBOOK_DEST}"

cat > "${ROOT}/docs/decisions/GOVERNANCE-ARCHITECTURE-BASELINE.md" <<'EOF'
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
EOF

cat > "${ROOT}/docs/adr/ADR-0001-CONTROLLER-RECONCILIATION-PATTERN.md" <<'EOF'
# ADR-0001 — Controller and reconciliation pattern

## Stato

Accepted.

## Decisione

Il comportamento centrale segue il controller pattern:

observed state -> desired/governed state -> reconciliation -> verification.

Si preferiscono controller piccoli, ciascuno responsabile di un aspetto
specifico dello stato, evitando un motore monolitico.

## Fonti ufficiali

- https://kubernetes.io/docs/concepts/architecture/controller/
- https://kubernetes.io/docs/concepts/extend-kubernetes/operator/

## Conseguenze

- il runtime non dipende dalla piattaforma corrente;
- gli adapter implementano integrazioni concrete;
- ogni ciclo è idempotente o rileva esplicitamente quando non può esserlo;
- errori e risultati intermedi sono persistiti.
EOF

cat > "${ROOT}/docs/adr/ADR-0002-POLICY-DECISION-POINT.md" <<'EOF'
# ADR-0002 — External policy decision point

## Stato

Accepted as architecture; implementation candidate not installed.

## Decisione

La valutazione delle policy viene separata dall'esecuzione.

Open Policy Agent è il candidato primario perché:

- è un policy engine general-purpose;
- riceve input strutturato;
- separa decisione ed enforcement;
- supporta policy dichiarative;
- produce decision identifier e decision logs;
- supporta bundle versionati e firmabili.

## Fonti ufficiali

- https://www.openpolicyagent.org/docs
- https://www.openpolicyagent.org/docs/management-decision-logs
- https://www.openpolicyagent.org/docs/management-bundles

## Condizione di installazione

OPA verrà installato solo dopo la definizione degli schemi di input/output
e dei test delle prime policy.
EOF

cat > "${ROOT}/docs/adr/ADR-0003-ANSIBLE-EXECUTION-ENGINE.md" <<'EOF'
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
EOF

cat > "${ROOT}/docs/adr/ADR-0004-DISCOVERY-AND-OBSERVABILITY.md" <<'EOF'
# ADR-0004 — Discovery and observability boundaries

## Stato

Accepted.

## Decisione

- Nmap produce observation candidate e non identità autorevole.
- Le API ufficiali confermano tecnologia, identità e capability.
- Prometheus conserva metriche temporali.
- Alertmanager instrada eventi e notifiche.
- SANDRA correla evidenze e decide secondo policy.

## Fonte ufficiale Nmap

- https://nmap.org/book/man-host-discovery.html
- https://nmap.org/book/man-version-detection.html
EOF

cat > "${ROOT}/docs/glossary/GLOSSARY.md" <<'EOF'
# Glossary

- **Controller**: processo che riconcilia stato osservato e stato governato.
- **Object**: entità persistente dell'ambiente gestito.
- **Observation**: fatto raccolto da una fonte.
- **Evidence**: osservazione con provenienza, tempo e integrità.
- **Capability**: operazione astratta e versionata.
- **Adapter**: implementazione tecnologica di una porta o capability.
- **Policy**: regola dichiarativa che assegna authority e limiti.
- **Authority**: delega concessa a una capability su una classe di oggetti.
- **Plan**: sequenza immutabile di precheck, azioni e postcheck.
- **Execution**: applicazione del piano mediante uno strumento.
- **Verification**: controllo indipendente del risultato.
- **Reconciliation**: processo che riduce la differenza fra stato osservato
  e stato governato.
- **Escalation**: richiesta di decisione umana perché la policy non produce
  un risultato univoco.
EOF

cat > "${ROOT}/src/runbooks/README.md" <<'EOF'
# RunBook sources

Questa directory contiene le sorgenti canoniche delle RunBook che modificano
Knowledge, runtime o ambiente gestito.

Ogni RunBook deve:

- caricare core.sh e knowledge.sh;
- essere eseguita come processo Bash dedicato;
- creare backup prima delle modifiche;
- verificare precondizioni e postcondizioni;
- produrre artifact;
- aggiornare Knowledge e GitHub nella stessa transazione quando applicabile.
EOF

install -d -m 0755 "$(dirname "${JOURNAL}")"

cat > "${JOURNAL}" <<EOF
# ${SANDRA_RUNBOOK_ID} — Governance architecture baseline

- Run ID: \`${SANDRA_RUN_ID}\`
- Modifiche remote all'Habitat: \`NONE\`
- Nuovi software installati: \`NONE\`

## Risultato

- registrato controller/reconciliation pattern;
- registrato OPA come policy engine candidato;
- registrato Ansible Core come execution engine candidato;
- definiti confini di Nmap, Prometheus e Alertmanager;
- riparate le directory dichiarate dal Knowledge manifest;
- aggiunto glossario canonico;
- aggiunta sorgente RunBook canonica.
EOF

python3 - \
    "${STATE}" \
    "${SANDRA_RUNBOOK_ID}" \
    "${SANDRA_RUN_ID}" \
    "${JOURNAL#${ROOT}/}" <<'PYTHON'
import datetime
import json
import pathlib
import sys

state_path = pathlib.Path(sys.argv[1])
runbook_id = sys.argv[2]
run_id = sys.argv[3]
journal = sys.argv[4]

state = json.loads(state_path.read_text(encoding="utf-8"))

current = state["spec"]["roadmap"]["current_gate"]["runbook"]
if current != "RB-000069":
    raise SystemExit(
        f"STATE_UNEXPECTED_CURRENT_GATE:{current}"
    )

state["metadata"]["state_version"] = "3.0.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(datetime.timezone.utc)
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["spec"]["roadmap"] = {
    "goal": "SANDRA V3",
    "current_gate": {
        "runbook": "R3-000001",
        "title": "Governance Architecture Baseline",
        "type": "architecture_knowledge_transition",
        "targets": [
            "repository SANDRA",
            "Knowledge canonica",
        ],
        "excluded_targets": [
            "sistemi remoti dell'Habitat",
        ],
        "objectives": [
            "adottare controller e reconciliation pattern",
            "separare policy decision ed enforcement",
            "definire confini degli strumenti esterni",
            "riparare la struttura Knowledge dichiarata",
            "preparare Object and Evidence Model",
        ],
        "prohibitions": [
            "nessuna modifica ai target remoti",
            "nessuna installazione software",
            "nessuna AI decisionale",
            "nessuna vista generata modificata manualmente",
            "nessuna correzione ad intuito",
        ],
    },
    "next_gate": {
        "runbook": "R3-000002",
        "title": "Object and Evidence Model",
        "status": "blocked",
    },
    "candidates": {
        "open_policy_agent": "accepted_pending_contract",
        "ansible_core": "accepted_pending_vertical_slice",
        "nmap": "accepted_pending_discovery_contract",
        "prometheus": "accepted_existing_or_pending_runtime_audit",
        "alertmanager": "accepted_existing_or_pending_runtime_audit",
        "sqlite_or_postgresql": "deferred_to_operational_data_model",
    },
    "out_of_scope": [
        "interfaccia grafica",
        "AI decisionale",
        "modifiche remote durante il gate",
        "installazione strumenti prima dei contratti",
    ],
}

principles = state["spec"].setdefault("principles", [])
for principle in [
    "controller e reconciliation loop come modello operativo",
    "policy decision separata dall'enforcement",
    "autonomia delegata dalle policy",
    "strumenti maturi orchestrati, non reinventati",
    "nessuna correzione ad intuito",
]:
    if principle not in principles:
        principles.append(principle)

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": "Governance Architecture Baseline",
    "current_gate": "R3-000001",
    "current_gate_status": "in_progress",
    "next_gate": "R3-000002",
}

state["status"]["governance_architecture_v3"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "registered",
    "controller_pattern": "accepted",
    "policy_decision_point": "opa_candidate",
    "execution_engine": "ansible_core_candidate",
    "remote_habitat_modifications": "none",
    "software_installed": "none",
}

state_path.write_text(
    json.dumps(state, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
PYTHON

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: register governance architecture baseline"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

{
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'KNOWLEDGE_STATUS=PASS\n'
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
