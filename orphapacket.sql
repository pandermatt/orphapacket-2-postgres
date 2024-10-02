-- Create schema orphanet if it doesn't exist
CREATE SCHEMA IF NOT EXISTS orphanet;

-- Drop tables if they already exist
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

-- Create the main Orphapackets table
CREATE TABLE orphanet.orphapackets (
    orphacode INT PRIMARY KEY,  -- Use Orphacode as the primary key
    label TEXT,
    creation_date TIMESTAMP,
    purl TEXT,
    disorder_type TEXT,
    disorder_type_purl TEXT
);

-- Add index on orphacode, though it's the primary key and automatically indexed
CREATE INDEX idx_orphacode ON orphanet.orphapackets(orphacode);

-- Table for Disorder Synonyms
CREATE TABLE orphanet.disorder_synonyms (
    id SERIAL PRIMARY KEY,
    orphacode INT REFERENCES orphanet.orphapackets(orphacode),
    synonym TEXT
);

-- Add index on orphacode for faster joins
CREATE INDEX idx_disorder_synonyms_orphacode ON orphanet.disorder_synonyms(orphacode);

-- Table for Phenotypes (1:M relation for phenotypes)
CREATE TABLE orphanet.phenotypes (
    id SERIAL PRIMARY KEY,
    hpo_id TEXT UNIQUE,  -- Ensure hpo_id is unique
    hpo_term TEXT
);

-- Add index on hpo_id for fast queries on phenotypes
CREATE INDEX idx_hpo_id ON orphanet.phenotypes(hpo_id);

-- 1:M relation table between Orphapackets and Phenotypes with frequency
CREATE TABLE orphanet.orphapackets_phenotypes (
    id SERIAL PRIMARY KEY,
    orphacode INT REFERENCES orphanet.orphapackets(orphacode),
    phenotype_id INT REFERENCES orphanet.phenotypes(id),
    hpo_frequency TEXT
);

-- Add indexes on foreign keys for faster joins
CREATE INDEX idx_phenotypes_orphacode ON orphanet.orphapackets_phenotypes(orphacode);
CREATE INDEX idx_phenotypes_phenotype_id ON orphanet.orphapackets_phenotypes(phenotype_id);

-- Table for Genes
CREATE TABLE orphanet.genes (
    id SERIAL PRIMARY KEY,
    orphacode INT REFERENCES orphanet.orphapackets(orphacode),
    symbol TEXT,
    name TEXT,
    disorder_gene_association_type TEXT
);

-- Table for External References with constraints
CREATE TABLE orphanet.external_references (
    id SERIAL PRIMARY KEY,
    source TEXT,
    reference TEXT,
    mapping_relation TEXT,
    orphacode INT REFERENCES orphanet.orphapackets(orphacode),
    gene_id INT REFERENCES orphanet.genes(id),
    CONSTRAINT chk_at_least_one_ref CHECK (gene_id IS NOT NULL OR orphacode IS NOT NULL)  -- Ensure at least one of the two is not null
);

-- Add indexes on orphacode and gene_id for faster lookups
CREATE INDEX idx_references_orphacode ON orphanet.external_references(orphacode);
CREATE INDEX idx_references_gene_id ON orphanet.external_references(gene_id);

-- Table for Text Sections
CREATE TABLE orphanet.text_sections (
    id SERIAL PRIMARY KEY,
    orphacode INT REFERENCES orphanet.orphapackets(orphacode),
    text_section_type TEXT,
    contents TEXT
);

-- Add index on orphacode for fast joins with orphapackets
CREATE INDEX idx_text_sections_orphacode ON orphanet.text_sections(orphacode);

-- Table for Prevalences
CREATE TABLE orphanet.prevalences (
    id SERIAL PRIMARY KEY,
    orphacode INT REFERENCES orphanet.orphapackets(orphacode),
    source TEXT,
    prevalence_type TEXT,
    prevalence_qualification TEXT,
    prevalence_class TEXT,
    val_moy TEXT,
    prevalence_geographic TEXT
);

-- Add index on orphacode for faster joins
CREATE INDEX idx_prevalences_orphacode ON orphanet.prevalences(orphacode);

-- Table for Average Age of Onsets with unique constraint
CREATE TABLE orphanet.average_age_of_onsets (
    id SERIAL PRIMARY KEY,
    orphacode INT REFERENCES orphanet.orphapackets(orphacode),
    value TEXT
);

-- Add index on orphacode for faster joins
CREATE INDEX idx_average_age_of_onsets_orphacode ON orphanet.average_age_of_onsets(orphacode);

-- Table for Type of Inheritances with unique constraint
CREATE TABLE orphanet.type_of_inheritances (
    id SERIAL PRIMARY KEY,
    orphacode INT REFERENCES orphanet.orphapackets(orphacode),
    value TEXT
);

-- Add index on orphacode for faster joins
CREATE INDEX idx_type_of_inheritances_orphacode ON orphanet.type_of_inheritances(orphacode);

-- Add indexes on orphacode for faster joins
CREATE INDEX idx_genes_orphacode ON orphanet.genes(orphacode);

-- Add index on symbol for quick gene symbol lookups
CREATE INDEX idx_gene_symbol ON orphanet.genes(symbol);
