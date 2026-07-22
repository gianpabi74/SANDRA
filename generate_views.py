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
    data = json.loads(
        STATE_PATH.read_text(encoding="utf-8")
    )

    if data.get("schema_version") != 2:
        raise SystemExit("STATE_SCHEMA_VERSION_INVALID")

    return data


def bullets(values: list[str]) -> str:
    return "\n".join(f"- {value}" for value in values)


def markdown_code(value: object) -> str:
    return f"`{value}`"


def render_start_here(state: dict) -> str:
    project = state["project"]
    providers = state["providers"]
    next_task = state["next_task"]
    journal = project["current_certification"]["journal"]

    return f"""# SANDRA — Start Here

> GENERATED FILE — DO NOT EDIT MANUALLY  
> Source: `STATE.json`

Repository ufficiale: {project["repository"]}

Branch autorevole: `{project["branch"]}`

Stato aggiornato: `{project["updated_utc"]}`

## Ordine di lettura

1. [Stato canonico machine-readable](STATE.json)
2. [Baseline globale](BASELINE.md)
3. [Stato corrente](CURRENT_STATE.md)
4. [Prossimo task](NEXT_TASK.md)
5. [Roadmap corrente](docs/roadmap/ROADMAP.md)
6. Journal corrente: `{journal}`

## Regole operative

{bullets(state["principles"])}

## Stato sintetico

- Core: {state["core"]["status"]}, versione `{state["core"]["version"]}`.
- PVE: {providers["pve"]["status"]}, inventario e topologia.
- PBS: {providers["pbs"]["status"]}, versione `{providers["pbs"]["version"]}`.
- Windows: `{providers["windows"]["version"]}`, stato `{providers["windows"]["status"]}`.
- Linux: `{providers["linux"]["version"]}`, stato `{providers["linux"]["status"]}`.
- Prossimo gate: `{next_task["runbook"]}` — {next_task["title"]}.
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

Solo dopo approvazione:

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

Prosegui SANDRA dal repository ufficiale:

{project["repository"]}

Branch: `{project["branch"]}`.

Leggi prima `START-HERE.md` e segui l'ordine indicato.

Considera:

- `STATE.json` la fonte viva canonica;
- GitHub la fonte autorevole dello stato certificato;
- i Journal la cronologia immutabile.

Verifica che le viste generate siano coerenti con `STATE.json` e
prosegui esattamente dal gate dichiarato in `NEXT_TASK.md`.

Non cambiare architettura, non introdurre nuovi layer e non
scrivere codice oltre il gate approvato senza una motivazione
tecnica concreta.

Quando dico “procedi”, continua con il passo successivo della
roadmap. Produci un Bash soltanto quando è necessario eseguirlo
su SANDRA.
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
