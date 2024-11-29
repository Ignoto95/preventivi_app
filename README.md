# preventivi_app

A new Flutter project.
Info sul BE: 
Struttura file --> (sulla vm)

preventivi_backend/
├── node_modules/
├── package.json
├── .env
├── server.js          <-- Entry point principale del backend con la funzione preventivo
├── routes/
│   ├── preventivi.js  <-- Gestione delle API relative ai preventivi
│
└── config/
    └── db.js          <-- Configurazione della connessione al database MySQL


Info sul database: 
ER DB: 

+-----------------------+           +-----------------------+           +----------------------+
|       Cliente         |           |     Preventivo        |           |       Lavoro         |
+-----------------------+           +-----------------------+           +----------------------+
| id_cliente (PK)       |<------->  | id_preventivo (PK)    |<------->  | id_lavoro (PK)       |
| nome                  |           | data_preventivo       |           | tipo_lavoro          |
| cognome               |           | id_cliente (FK)       |           | descrizione_lavoro   |
| città                 |           | prezzo_finale         |           | prezzo               |
| via                   |           +-----------------------+           | caldaia              |
+-----------------------+                                               | data_caldaia         |
                                                                        | id_preventivo (FK)   |
                                                                        +----------------------+
1-Ogni Cliente può avere più Preventivi: Ogni cliente può ricevere più preventivi per diversi lavori.
2-Ogni Preventivo può avere più Lavori: Ogni preventivo può contenere più lavori (tipi di lavoro).
3-Il campo caldaia e data_caldaia si applicano a ciascun Lavoro. Se caldaia è TRUE, allora la data_caldaia deve essere valorizzata.
