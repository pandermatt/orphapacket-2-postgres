# Orphapacket Data Importer

This Python script imports Orphapacket data from JSON files into a PostgreSQL database. The JSON files can be downloaded from the [Orphanet Orphapacket repository](https://github.com/Orphanet/orphapacket).

## Features

- Inserts Orphapacket data, including genes, phenotypes, synonyms, text sections, average age of onset, type of inheritances, and prevalences.
- Handles relationships between Orphapackets and external references.

## Setup

Clone this repository and navigate to the project directory.
Create a `.env` file in the root of the project directory with the following content:

```env
DB_NAME=<database_name>
DB_USER=<database_user>
DB_PASSWORD=<database_password>
DB_HOST=<database_host>
DB_PORT=<database_port>
```

Create the tables in the database by running the following command:

```bash
source .env
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f orphapacket.sql
```


## Running the Script

1. Ensure you have your PostgreSQL database running and accessible.
   
2. Download the JSON files from the [Orphanet Orphapacket repository](https://github.com/Orphanet/orphapacket) and place them in a folder named `json` within the project directory.

3. Run the script to import data into the database:

    ```bash
    python import_orphapacket.py
    ```

    The script will automatically detect all JSON files in the `json` folder and begin importing them into the PostgreSQL database. Progress will be displayed with a progress bar.
