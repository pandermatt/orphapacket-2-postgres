CREATE SCHEMA IF NOT EXISTS orphanet;

DROP TABLE IF EXISTS orphanet.orphapackets_phenotypes CASCADE;

DROP TABLE IF EXISTS orphanet.phenotypes CASCADE;

DROP TABLE IF EXISTS orphanet.external_references CASCADE;

DROP TABLE IF EXISTS orphanet.text_sections CASCADE;

DROP TABLE IF EXISTS orphanet.prevalences CASCADE;

DROP TABLE IF EXISTS orphanet.average_age_of_onsets CASCADE;

DROP TABLE IF EXISTS orphanet.type_of_inheritances CASCADE;

DROP TABLE IF EXISTS orphanet.genes CASCADE;

DROP TABLE IF EXISTS orphanet.disorder_synonyms CASCADE;

DROP TABLE IF EXISTS orphanet.orphapackets CASCADE;

DROP TABLE IF EXISTS orphanet.parent_child CASCADE;

CREATE TABLE
    orphanet.orphapackets (
        orphacode INT PRIMARY KEY,
        label TEXT,
        creation_date TIMESTAMP,
        purl TEXT,
        disorder_type TEXT,
        disorder_type_purl TEXT
    );

CREATE INDEX idx_orphacode ON orphanet.orphapackets (orphacode);

CREATE TABLE
    orphanet.disorder_synonyms (
        id SERIAL PRIMARY KEY,
        orphacode INT REFERENCES orphanet.orphapackets (orphacode),
        synonym TEXT
    );

CREATE INDEX idx_disorder_synonyms_orphacode ON orphanet.disorder_synonyms (orphacode);

CREATE TABLE
    orphanet.phenotypes (
        id SERIAL PRIMARY KEY,
        hpo_id TEXT UNIQUE,
        hpo_term TEXT
    );

CREATE INDEX idx_hpo_id ON orphanet.phenotypes (hpo_id);

CREATE TABLE
    orphanet.orphapackets_phenotypes (
        id SERIAL PRIMARY KEY,
        orphacode INT REFERENCES orphanet.orphapackets (orphacode),
        phenotype_id INT REFERENCES orphanet.phenotypes (id),
        hpo_frequency TEXT
    );

CREATE INDEX idx_phenotypes_orphacode ON orphanet.orphapackets_phenotypes (orphacode);

CREATE INDEX idx_phenotypes_phenotype_id ON orphanet.orphapackets_phenotypes (phenotype_id);

CREATE TABLE
    orphanet.genes (
        id SERIAL PRIMARY KEY,
        orphacode INT REFERENCES orphanet.orphapackets (orphacode),
        symbol TEXT,
        name TEXT,
        disorder_gene_association_type TEXT
    );

CREATE TABLE
    orphanet.external_references (
        id SERIAL PRIMARY KEY,
        source TEXT,
        reference TEXT,
        mapping_relation TEXT,
        orphacode INT REFERENCES orphanet.orphapackets (orphacode),
        gene_id INT REFERENCES orphanet.genes (id),
        CONSTRAINT chk_at_least_one_ref CHECK (
            gene_id IS NOT NULL
            OR orphacode IS NOT NULL
        )
    );

CREATE INDEX idx_references_orphacode ON orphanet.external_references (orphacode);

CREATE INDEX idx_references_gene_id ON orphanet.external_references (gene_id);

CREATE TABLE
    orphanet.text_sections (
        id SERIAL PRIMARY KEY,
        orphacode INT REFERENCES orphanet.orphapackets (orphacode),
        text_section_type TEXT,
        contents TEXT
    );

CREATE INDEX idx_text_sections_orphacode ON orphanet.text_sections (orphacode);

CREATE TABLE
    orphanet.prevalences (
        id SERIAL PRIMARY KEY,
        orphacode INT REFERENCES orphanet.orphapackets (orphacode),
        source TEXT,
        prevalence_type TEXT,
        prevalence_qualification TEXT,
        prevalence_class TEXT,
        val_moy TEXT,
        prevalence_geographic TEXT
    );

CREATE INDEX idx_prevalences_orphacode ON orphanet.prevalences (orphacode);

CREATE TABLE
    orphanet.average_age_of_onsets (
        id SERIAL PRIMARY KEY,
        orphacode INT REFERENCES orphanet.orphapackets (orphacode),
        value TEXT
    );

CREATE INDEX idx_average_age_of_onsets_orphacode ON orphanet.average_age_of_onsets (orphacode);

CREATE TABLE
    orphanet.type_of_inheritances (
        id SERIAL PRIMARY KEY,
        orphacode INT REFERENCES orphanet.orphapackets (orphacode),
        value TEXT
    );

CREATE TABLE
    orphanet.parent_child (
        id SERIAL PRIMARY KEY,
        parent_orphacode INT REFERENCES orphanet.orphapackets (orphacode),
        child_orphacode INT REFERENCES orphanet.orphapackets (orphacode),
        CONSTRAINT chk_parent_child CHECK (parent_orphacode != child_orphacode),
        CONSTRAINT chk_unique_parent_child UNIQUE (parent_orphacode, child_orphacode)
    );

CREATE INDEX idx_parent_orphacode ON orphanet.parent_child (parent_orphacode);

CREATE INDEX idx_child_orphacode ON orphanet.parent_child (child_orphacode);

CREATE INDEX idx_type_of_inheritances_orphacode ON orphanet.type_of_inheritances (orphacode);

CREATE INDEX idx_genes_orphacode ON orphanet.genes (orphacode);

CREATE INDEX idx_gene_symbol ON orphanet.genes (symbol);
