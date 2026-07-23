#!/usr/bin/env python3

import argparse
import json
import pathlib
import sys
import tempfile


ROOT = pathlib.Path(__file__).resolve().parent
STATE_PATH = ROOT / "STATE.json"

VIEW_PATHS = {
    "START-HERE.md": ROOT / "START-HERE.md",
    "BASELINE.md": ROOT / "BASELINE.md",
    "CURRENT_STATE.md": ROOT / "CURRENT_STATE.md",
    "NEXT_TASK.md": ROOT / "NEXT_TASK.md",
    "docs/roadmap/ROADMAP.md": (
        ROOT / "docs/roadmap/ROADMAP.md"
    ),
    "CHAT-HANDOFF.md": ROOT / "CHAT-HANDOFF.md",
}


def load_state() -> dict:
    raw = json.loads(
        STATE_PATH.read_text(encoding="utf-8")
    )

    if set(raw) != {"metadata", "spec", "status"}:
        raise SystemExit("STATE_TOP_LEVEL_MODEL_INVALID")

    metadata = raw["metadata"]
    spec = raw["spec"]
    status = raw["status"]
    providers = status["providers"]
    current = status["current_certification"]
    roadmap_spec = spec["roadmap"]
    roadmap_status = status["roadmap"]

    principles = [
        "documentazione ufficiale come fonte primaria",
        "dati oggettivi prima del codice",
        "audit chirurgico prima delle assunzioni",
        "motore deterministico e nessuna AI decisionale",
        "Bash piccoli, accurati e con un solo obiettivo",
        "briefing proporzionati e roadmap stabile",
        "nessuna complessità senza valore operativo",
        "SANDRA finalizzata al governo autonomo dell'Habitat",
        "stato corrente riscritto e storia separata",
        "Knowledge e GitHub aggiornati nella stessa transazione",
    ]

    current_gate = roadmap_spec["current_gate"]
    next_gate = roadmap_spec["next_gate"]

    return {
        "project": {
            "name": metadata["project"],
            "repository": metadata["repository"],
            "branch": metadata["branch"],
            "updated_utc": metadata["updated_utc"],
            "current_certification": current,
        },
        "principles": principles,
        "core": status["components"]["core"],
        "providers": providers,
        "roadmap": {
            "phase": roadmap_status["phase"],
            "gates": [
                {
                    "runbook": current_gate["runbook"],
                    "title": current_gate["title"],
                    "status": roadmap_status[
                        "current_gate_status"
                    ],
                },
                {
                    "runbook": next_gate["runbook"],
                    "title": next_gate["title"],
                    "status": next_gate["status"],
                },
            ],
            "out_of_scope": [
                "nuove tecnologie prima della Architecture Baseline V2",
                "interfaccia grafica",
                "AI decisionale",
                "modifiche remote durante la migrazione Knowledge",
            ],
        },
        "next_task": {
            "runbook": current_gate["runbook"],
            "title": current_gate["title"],
            "type": "engineering_knowledge_migration",
            "targets": ["repository SANDRA", "Knowledge canonica"],
            "excluded_targets": ["sistemi remoti dell'Habitat"],
            "objectives": [
                "completare la Knowledge V2",
                "rigenerare tutte le viste canoniche",
                "validare la continuità fra sessioni",
                "sincronizzare e verificare GitHub",
            ],
            "prohibitions": [
                "nessuna modifica ai target remoti",
                "nessuna nuova tecnologia",
                "nessuna vista canonica modificata manualmente",
                "nessuna informazione critica lasciata soltanto in chat",
            ],
            "next_gate_after_approval": next_gate["runbook"],
        },
    }

def bullets(values: list[str]) -> str:
    return "\n".join(f"- {value}" for value in values)


def markdown_code(value: object) -> str:
    return f"`{value}`"


def render_start_here(state: dict) -> str:
    project = state["project"]
    providers = state["providers"]
    roadmap = state["roadmap"]
    next_task = state["next_task"]
    current = project["current_certification"]
    journal = current["journal"]

    gate_lines = []

    for item in roadmap["gates"]:
        mode = (
            f' — modalità `{item["mode"]}`'
            if "mode" in item
            else ""
        )

        gate_lines.append(
            f'- **{item["runbook"]}** — '
            f'{item["title"]} — '
            f'stato `{item["status"]}`'
            f'{mode}'
        )

    gates = "\n".join(gate_lines)

    return f"""# SANDRA — Start Here

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

## Ripartenza rapida

Repository ufficiale: {project["repository"]}

Branch autorevole: `{project["branch"]}`

Per continuare in una nuova chat:

1. fornire il link del repository;
2. chiedere di leggere `START-HERE.md`;
3. proseguire esclusivamente dal gate indicato in `NEXT_TASK.md`.

Prompt pronto:

```text
{project["repository"]}

Leggi START-HERE.md e continua SANDRA dal gate corrente,
rispettando Costituzione, Knowledge e roadmap.
```

## Stato canonico

- aggiornato UTC: `{project["updated_utc"]}`;
- certificazione corrente: `{current["runbook"]}`;
- [Journal corrente]({journal});
- gate corrente: `{next_task["runbook"]}` — {next_task["title"]}.

## Indice operativo

1. [Stato canonico machine-readable](STATE.json)
2. [Project Charter](PROJECT_CHARTER.md)
3. [Scheletro costituzionale](docs/constitution/CANONICAL-SKELETON.md)
4. [Costituzione della continuità](docs/constitution/KNOWLEDGE-CONTINUITY.md)
5. [Baseline globale](BASELINE.md)
6. [Stato corrente](CURRENT_STATE.md)
7. [Prossimo task](NEXT_TASK.md)
8. [Roadmap corrente](docs/roadmap/ROADMAP.md)
9. [Prompt minimale di handoff](CHAT-HANDOFF.md)
10. [Journal corrente]({journal})

## Indice dei gate

{gates}

## Regole operative

{bullets(state["principles"])}

## Stato sintetico

- Core: {state["core"]["status"]}, versione `{state["core"]["version"]}`.
- PVE: {providers["pve"]["status"]}.
- PBS: {providers["pbs"]["status"]}, versione `{providers["pbs"]["version"]}`.
- Windows: `{providers["windows"]["version"]}`, stato `{providers["windows"]["status"]}`.
- Linux: `{providers["linux"]["version"]}`, stato `{providers["linux"]["status"]}`.
"""


def render_baseline(state: dict) -> str:
    project = state["project"]
    providers = state["providers"]
    current = project["current_certification"]
    linux = providers["linux"]

    target_names = [
        item["name"]
        for item in linux["targets"]
    ]

    return f"""# SANDRA — Baseline globale certificata

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

Aggiornato: `{project["updated_utc"]}`

Repository: {project["repository"]}

Branch: `{project["branch"]}`

RunBook corrente: `{current["runbook"]}`

Journal corrente: `{current["journal"]}`

## Principi permanenti

{bullets(state["principles"])}

## Core

- versione: `{state["core"]["version"]}`;
- stato: `{state["core"]["status"]}`;
- capability:
{bullets(state["core"]["capabilities"])}

## Provider PVE

- versione: `{providers["pve"]["version"]}`;
- stato: `{providers["pve"]["status"]}`;
- responsabilità:
{bullets(providers["pve"]["scope"])}

## Provider PBS

- versione: `{providers["pbs"]["version"]}`;
- stato: `{providers["pbs"]["status"]}`;
- target: `{providers["pbs"]["target"]}`.

## Provider Windows

- versione: `{providers["windows"]["version"]}`;
- stato: `{providers["windows"]["status"]}`;
- baseline: `{providers["windows"]["baseline"]}`;
- capability:
{bullets(providers["windows"]["capabilities"])}

## Provider Linux

- versione: `{linux["version"]}`;
- stato: `{linux["status"]}`;
- trasporto: `{linux["transport"]["protocol"]}`;
- autenticazione: `{linux["transport"]["authentication"]}`;
- StrictHostKeyChecking: `{str(linux["transport"]["strict_host_key_checking"]).lower()}`;
- Get: `{linux["capabilities"]["Get"]}`;
- Test: `{linux["capabilities"]["Test"]}`;
- Set: `{linux["capabilities"]["Set"]}`;
- target certificati:
{bullets(target_names)}

## Prossimo gate

`{state["next_task"]["runbook"]}` — {state["next_task"]["title"]}

Tipo: `{state["next_task"]["type"]}`.
"""


def render_current_state(state: dict) -> str:
    project = state["project"]
    providers = state["providers"]
    linux = providers["linux"]
    current = project["current_certification"]

    targets = "\n".join(
        f'- {item["name"]} — `{item["ip"]}`'
        for item in linux["targets"]
    )

    degraded_lines = []

    for host, units in (
        linux["observed_state"]
        ["systemd_degraded"]
        .items()
    ):
        degraded_lines.append(
            f"- {host}: degraded — "
            + ", ".join(f"`{unit}`" for unit in units)
        )

    return f"""# SANDRA — Current State

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

Aggiornato: `{project["updated_utc"]}`

## Repository

- URL: {project["repository"]}
- branch: `{project["branch"]}`
- stato canonico: `STATE.json`

## Core

- versione: `{state["core"]["version"]}`
- stato: `{state["core"]["status"]}`

## Provider PVE

- versione: `{providers["pve"]["version"]}`
- stato: `{providers["pve"]["status"]}`
- responsabilità: inventario e topologia

## Provider PBS

- versione: `{providers["pbs"]["version"]}`
- stato: `{providers["pbs"]["status"]}`

## Provider Windows

- versione: `{providers["windows"]["version"]}`
- stato: `{providers["windows"]["status"]}`
- capability:
{bullets(providers["windows"]["capabilities"])}

## Provider Linux

- versione: `{linux["version"]}`
- stato: `{linux["status"]}`
- trasporto: `{linux["transport"]["protocol"]}`
- autenticazione: `{linux["transport"]["authentication"]}`
- Get: `{linux["capabilities"]["Get"]}`
- Test: `{linux["capabilities"]["Test"]}`
- Set: `{linux["capabilities"]["Set"]}`
- delta invarianti: `{linux["observed_state"]["invariant_delta"]}`

## Target Linux

{targets}

Esclusi:

{bullets(linux["excluded_targets"])}

## Stato systemd noto

{chr(10).join(degraded_lines)}

## Certificazione corrente

- RunBook: `{current["runbook"]}`
- Journal: `{current["journal"]}`

## Prossimo gate

`{state["next_task"]["runbook"]}` — {state["next_task"]["title"]}
"""


def render_next_task(state: dict) -> str:
    task = state["next_task"]

    return f"""# Next Task

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

## {task["runbook"]} — {task["title"]}

### Tipo

`{task["type"]}`

### Target

{bullets(task["targets"])}

### Target esclusi

{bullets(task["excluded_targets"])}

### Obiettivi

{bullets(task["objectives"])}

### Divieti

{bullets(task["prohibitions"])}

### Gate successivo

Solo dopo il completamento deterministico del gate corrente:

`{task["next_gate_after_approval"]}`
"""


def render_roadmap(state: dict) -> str:
    project = state["project"]
    roadmap = state["roadmap"]

    gates = "\n".join(
        (
            f'{index}. **{item["runbook"]}** — '
            f'{item["title"]} '
            f'(`{item["status"]}`'
            + (
                f', `{item["mode"]}`'
                if "mode" in item
                else ""
            )
            + ")"
        )
        for index, item in enumerate(
            roadmap["gates"],
            start=1,
        )
    )

    return f"""# SANDRA — Roadmap corrente

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

Aggiornato: `{project["updated_utc"]}`

## Fase corrente

`{roadmap["phase"]}`

## Gate

{gates}

## Fuori perimetro corrente

{bullets(roadmap["out_of_scope"])}

## Vincoli permanenti

{bullets(state["principles"])}

- `STATE.json` è la sorgente viva canonica.
- Le viste Markdown sono generate.
- I Journal sono immutabili.
- GitHub deve essere sincronizzato prima della chiusura della RB.
"""


def render_handoff(state: dict) -> str:
    project = state["project"]

    return f"""# Prompt minimale per una nuova chat

> GENERATED FILE — DO NOT EDIT MANUALLY
> Source: `STATE.json`

Repository ufficiale:

{project["repository"]}

Branch autorevole: `{project["branch"]}`.

Leggi `START-HERE.md` prima di proporre o modificare qualsiasi cosa.

La nuova sessione deve:

1. basarsi sullo stato corrente del repository;
2. consultare frequentemente le documentazioni ufficiali;
3. usare soltanto dati oggettivi e contratti certificati;
4. richiedere export o audit chirurgici quando mancano dati;
5. evitare codice lungo, creativo o fondato su assunzioni;
6. rispettare Costituzione, architettura e roadmap approvate;
7. non riaprire decisioni senza nuove evidenze reali;
8. aggiornare con precisione Knowledge, viste e Journal;
9. eseguire commit, push e verifica di `origin/main`;
10. lasciare il repository pronto per la sessione successiva.

Quando l'utente dice “procedi”, continua dal singolo gate dichiarato
in `NEXT_TASK.md`.

Nessuna informazione necessaria alla prosecuzione deve rimanere
esclusivamente nella conversazione.
"""

def render_all(state: dict) -> dict[str, str]:
    return {
        "START-HERE.md": render_start_here(state),
        "BASELINE.md": render_baseline(state),
        "CURRENT_STATE.md": render_current_state(state),
        "NEXT_TASK.md": render_next_task(state),
        "docs/roadmap/ROADMAP.md": render_roadmap(state),
        "CHAT-HANDOFF.md": render_handoff(state),
    }


def write_views(rendered: dict[str, str]) -> None:
    for relative, content in rendered.items():
        path = VIEW_PATHS[relative]
        path.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        path.write_text(
            content.rstrip() + "\n",
            encoding="utf-8",
        )


def check_views(rendered: dict[str, str]) -> None:
    failures = []

    for relative, expected in rendered.items():
        path = VIEW_PATHS[relative]
        expected = expected.rstrip() + "\n"

        if not path.is_file():
            failures.append(
                f"MISSING:{relative}"
            )
            continue

        actual = path.read_text(
            encoding="utf-8"
        )

        if actual != expected:
            failures.append(
                f"DRIFT:{relative}"
            )

    if failures:
        raise SystemExit(
            "GENERATED_VIEW_INVALID:"
            + ",".join(failures)
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
    )

    args = parser.parse_args()
    state = load_state()
    rendered = render_all(state)

    if args.check:
        check_views(rendered)
        print("KNOWLEDGE_GENERATED_VIEWS=PASS")
    else:
        write_views(rendered)
        print("KNOWLEDGE_GENERATED_VIEWS=UPDATED")


if __name__ == "__main__":
    main()
