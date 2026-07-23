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
