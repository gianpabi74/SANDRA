# SANDRA — Project Charter e Costituzione operativa V2

## Missione

SANDRA V2 è il sistema deterministico e autonomo incaricato di
scoprire, comprendere, verificare e governare operativamente gli
oggetti e le tecnologie dell'Habitat.

SANDRA non ha come fine la sola osservazione. L'osservazione produce
evidenze necessarie al governo, alla verifica, alla protezione e al
ripristino dell'Habitat.

SANDRA è parte dell'Habitat. La propria continuità dipende dalla
continuità dell'Habitat e deve, a sua volta, contribuire alla sua
resilienza, sopravvivenza e ricostruzione.

## Obiettivo corrente

L'obiettivo approvato è SANDRA V2: governo autonomo dell'Habitat
concreto mediante contratti neutrali, implementazioni deterministiche
e interfacce ufficiali.

Una possibile V3 universale non costituisce un requisito corrente.
La V2 non deve però introdurre dipendenze irreversibili dall'Habitat
attuale quando una soluzione neutrale altrettanto semplice è
disponibile.

## Principi costituzionali

### 1. Autorità delle fonti ufficiali

Ogni decisione tecnica deve basarsi prioritariamente sulla
documentazione ufficiale e corrente delle tecnologie coinvolte.

La documentazione ufficiale deve essere consultata nuovamente quando
cambiano versioni, API, comandi, capability o presupposti tecnici.

Fonti comunitarie possono aiutare la diagnosi, ma non sostituiscono
il contratto ufficiale senza una motivazione esplicita.

### 2. Oggettività prima del codice

SANDRA non implementa comportamenti fondati su supposizioni,
intuizioni, nomi amministrativi o associazioni creative.

Ogni implementazione deve derivare da dati osservati, esportazioni,
interfacce ufficiali, contratti certificati o requisiti approvati.

Quando manca un dato necessario, non deve essere inventato.

### 3. Audit prima delle assunzioni

Quando le evidenze sono insufficienti, si richiede un'esportazione o
si esegue un audit chirurgico read-only prima di proporre una
modifica.

L'audit deve rispondere a una domanda precisa, essere piccolo,
leggibile, non modificativo e produrre soltanto l'evidenza necessaria.

### 4. Determinismo verificabile

A parità di input, configurazione e versione del codice, SANDRA deve
produrre lo stesso risultato.

Decisioni operative non possono dipendere da AI, interpretazione
libera, casualità, euristiche opache o output destinati esclusivamente
alla lettura umana.

SANDRA può dichiarare esplicitamente che un oggetto è non risolto,
ambiguo o in conflitto. Non deve inventare una risposta.

### 5. Derivazione architetturale

Prima di progettare un componente originale si deve verificare se il
problema sia già risolto da:

- uno standard consolidato;
- un modello architetturale affermato;
- software libero maturo;
- un'interfaccia ufficiale della tecnologia.

Il codice originale è ammesso soltanto per integrazione,
normalizzazione e applicazione dei contratti minimi di SANDRA.

### 6. Gate di Necessità Ingegneristica

Prima di proporre o implementare una modifica si deve verificare che:

1. risolva un problema reale, osservato e dimostrabile;
2. produca un'evoluzione operativa misurabile;
3. sia coerente con la missione e l'architettura corrente;
4. sia coerente con documentazione ufficiale e pratiche consolidate;
5. non duplichi una capability già disponibile;
6. introduca complessità nulla o strettamente necessaria;
7. sia necessaria nel gate corrente della roadmap;
8. disponga di verifica, rollback e ciclo di vita documentabile.

Una proposta che supera il gate diventa candidata alla valutazione.
Non viene applicata automaticamente.

### 7. Semplicità misurabile

Ogni tecnologia, livello o dipendenza deve giustificare il proprio
costo operativo.

Una soluzione deve essere respinta quando introduce più codice,
configurazione, manutenzione, dipendenze o rischi del problema che
risolve.

### 8. Responsabilità unica

Ogni componente e documento deve avere una responsabilità chiaramente
definita e un solo owner.

Quando un componente assume responsabilità appartenenti a un altro,
l'attività deve fermarsi prima di continuare.

### 9. Separazione permanente

- chi osserva non decide;
- chi decide non esegue;
- chi esegue non verifica;
- chi verifica non modifica;
- chi conserva lo stato corrente non ricostruisce la storia;
- chi ricorda non reinventa la verità.

### 10. Operatività

Il flusso operativo di riferimento è:

`Detect → Get → Test → Decide → Set → Verify → Record`

Non tutte le tecnologie devono supportare ogni fase. Per ciascuna
tecnologia devono essere dichiarati con precisione il perimetro
governabile, le esclusioni e le motivazioni.

### 11. Autonomia prudente

SANDRA deve governare l'Habitat con la minima interazione umana
possibile senza sacrificare sicurezza e determinismo.

Autonomia significa saper decidere quando:

- agire;
- non agire;
- approfondire;
- riprovare;
- applicare rollback;
- isolare un singolo oggetto;
- continuare sugli altri oggetti.

Un errore locale deve avere il minore raggio d'impatto possibile.

### 12. Bash piccoli e accurati

Ogni RunBook Bash deve essere quanto più breve possibile senza
sacrificare sicurezza, verifica, evidenze e atomicità.

Ogni RunBook deve:

- usare il preambolo costituzionale;
- avere un solo obiettivo principale;
- validare le precondizioni;
- evitare parser e scansioni generiche non necessarie;
- arrestarsi esplicitamente in caso di errore;
- verificare il risultato;
- produrre un artifact;
- aggiornare la Knowledge nella stessa transazione quando cambia
  tecnologia, architettura o stato certificato.

Una RunBook lunga è ammessa soltanto quando dividerla comprometterebbe
l'atomicità o la sicurezza.

### 13. Briefing proporzionati

Un briefing deve chiarire una decisione, non riaprirla continuamente.

Dopo l'approvazione di una direzione non devono essere prodotte
ripetutamente nuove varianti dello stesso argomento, salvo nuove
evidenze, incompatibilità o rischi reali.

### 14. Stabilità della roadmap

La roadmap approvata è il percorso operativo corrente.

Non deve cambiare a ogni nuova idea. Una variazione richiede:

- evidenze nuove;
- problema o contraddizione dimostrata;
- analisi dell'impatto sul lavoro certificato;
- decisione esplicita;
- aggiornamento atomico della Knowledge.

### 15. Onestà ingegneristica

Quando nuove evidenze dimostrano che una decisione precedente è
errata, incompleta o sproporzionata, la decisione deve essere
rivalutata.

Non si continua per inerzia, orgoglio o costo già sostenuto.

### 16. Debito tecnico esplicito

È vietato lasciare debito tecnico implicito.

Ogni rinvio deve indicare almeno motivo, impatto, stato e gate futuro.
Un `TODO` senza contesto non costituisce documentazione sufficiente.

### 17. Provenienza delle evidenze

Ogni fatto operativo importante deve conservare almeno:

- fonte;
- target;
- momento di osservazione;
- strumento e versione;
- percorso dell'evidenza;
- risultato.

Un fatto osservato, una deduzione e una decisione devono rimanere
distinguibili.

### 18. Ciclo di vita delle tecnologie

Prima di introdurre un componente esterno devono essere valutati e
documentati:

- installazione;
- configurazione;
- aggiornamento;
- backup;
- restore;
- disinstallazione;
- dipendenze;
- comportamento in caso di guasto;
- rollback.

L'installazione non conclude il costo operativo della tecnologia.

### 19. Sicurezza

Secret, chiavi, token e dati sensibili non devono comparire nella
Knowledge, su Git, nei log o negli artifact.

Ogni nuova capability deve valutare esplicitamente il rischio di
cattura accidentale tramite output, trace, dump, configurazioni ed
esportazioni.

### 20. Una sola verità per responsabilità

Devono esistere:

- una missione vigente;
- una Costituzione vigente;
- un'architettura corrente;
- uno stato canonico machine-readable;
- una roadmap corrente;
- un gate corrente;
- un entrypoint;
- un generatore delle viste derivate.

Le duplicazioni non costituiscono backup. Costituiscono rischio di
divergenza.

### 21. Stato corrente e storia

I documenti canonici descrivono esclusivamente il presente e vengono
riscritti quando SANDRA evolve.

La storia appartiene a Git, Journal, ADR e artifact certificati.
Una nuova sessione non deve ricostruire il presente leggendo tutta la
cronologia.

### 22. Continuità indipendente dalla conversazione

Ogni sessione deve concludersi considerando che la sessione
successiva non possieda alcun contesto conversazionale precedente.

Nessuna informazione necessaria alla prosecuzione può esistere
esclusivamente nella chat, nella memoria dell'operatore, in un file
locale non sincronizzato o in un artifact non indicizzato.

### 23. Obbligo della sessione futura

Ogni nuova sessione deve:

1. leggere `START-HERE.md` prima di proporre modifiche;
2. verificare stato canonico, architettura, roadmap e gate corrente;
3. lavorare esclusivamente sul gate approvato;
4. aggiornare con dovizia e precisione i documenti canonici coinvolti;
5. rigenerare e validare le viste;
6. committare e pubblicare le modifiche;
7. verificare che il repository remoto rappresenti lo stato corrente;
8. lasciare il progetto pronto per una sessione successiva priva di
   contesto.

### 24. Conservazione della conoscenza

Ogni evoluzione deve mantenere o aumentare la conoscenza permanente
del progetto.

Nessuna modifica è completa se riduce la capacità di una futura
sessione di comprendere, proseguire e governare SANDRA leggendo
soltanto il repository sincronizzato.

## Regola di continuità

Per continuare SANDRA non deve essere necessario ricordare il passato:
deve essere sufficiente leggere il presente canonico.

## Definition of Done

Una transazione SANDRA è conclusa esclusivamente quando:

- il problema e il criterio di successo sono espliciti;
- le precondizioni sono state verificate;
- la modifica tecnica è stata completata;
- il risultato reale è stato verificato;
- la Knowledge pertinente rappresenta il nuovo stato corrente;
- `STATE.json` è coerente;
- le viste canoniche sono state rigenerate;
- il Journal del run è stato scritto;
- `NEXT_TASK.md` identifica un solo passo successivo;
- la roadmap è stata aggiornata quando necessario;
- le modifiche sono state committate;
- il push verso GitHub è stato eseguito;
- il commit remoto è stato verificato;
- l'artifact è stato creato ed esportato;
- una nuova sessione può continuare senza la chat precedente.

La documentazione non è successiva alla modifica: è parte della stessa
transazione ingegneristica.
