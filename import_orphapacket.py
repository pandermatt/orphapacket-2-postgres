import json
import psycopg2
from dotenv import load_dotenv
import os
from alive_progress import alive_bar

load_dotenv()

DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")

conn = psycopg2.connect(dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, host=DB_HOST, port=DB_PORT)
cur = conn.cursor()


def insert_from_data(data):
    orphapacket = data["Orphapacket"]

    cur.execute("SELECT orphacode FROM orphanet.orphapackets WHERE orphacode = %s", (orphapacket["ORPHAcode"],))
    if cur.fetchone():
        return

    print(f"Inserting {orphapacket['ORPHAcode']}")

    cur.execute(
        """
        INSERT INTO orphanet.orphapackets (orphacode, label, creation_date, purl, disorder_type, disorder_type_purl)
        VALUES (%s, %s, %s, %s, %s, %s) RETURNING orphacode
        """,
        (
            orphapacket["ORPHAcode"],
            orphapacket["Label"],
            orphapacket["creationDate"],
            orphapacket["PURL"],
            orphapacket["DisorderType"]["value"],
            orphapacket["DisorderType"]["PURL"],
        ),
    )
    orphacode = cur.fetchone()[0]

    orphapacket.pop("ORPHAcode")
    orphapacket.pop("Label")
    orphapacket.pop("creationDate")
    orphapacket.pop("PURL")
    orphapacket.pop("DisorderType")

    if "Synonyms" in orphapacket:
        for synonym in orphapacket["Synonyms"]:
            cur.execute(
                "INSERT INTO orphanet.disorder_synonyms (orphacode, synonym) VALUES (%s, %s)",
                (orphacode, synonym["Synonym"]),
            )
        orphapacket.pop("Synonyms")

    if "Genes" in orphapacket:
        for gene_entry in orphapacket["Genes"]:
            gene = gene_entry["Gene"]
            cur.execute(
                """
                INSERT INTO orphanet.genes (orphacode, symbol, name, disorder_gene_association_type)
                VALUES (%s, %s, %s, %s) RETURNING id
                """,
                (orphacode, gene["Symbol"], gene["Name"], gene["DisorderGeneAssociationType"]),
            )
            gene_id = cur.fetchone()[0]

            if "ExternalReferences" in gene:
                for reference in gene["ExternalReferences"]:
                    cur.execute(
                        """
                        INSERT INTO orphanet.external_references (gene_id, source, reference)
                        VALUES (%s, %s, %s)
                        """,
                        (gene_id, reference["Source"], reference["Reference"]),
                    )
        orphapacket.pop("Genes")

    if "ExternalReferences" in orphapacket:
        for reference in orphapacket["ExternalReferences"]:
            if "ExternalReference" in reference:
                reference = reference["ExternalReference"]
            cur.execute(
                """
                INSERT INTO orphanet.external_references (orphacode, source, reference, mapping_relation)
                VALUES (%s, %s, %s, %s)
                """,
                (orphacode, reference["Source"], reference["Reference"], reference["DisorderMappingRelation"]),
            )
        orphapacket.pop("ExternalReferences")

    if "Phenotypes" in orphapacket:
        for phenotype in orphapacket["Phenotypes"]:
            cur.execute(
                """
                SELECT id, hpo_term
                FROM orphanet.phenotypes
                WHERE hpo_id = %s
                """,
                (phenotype["Phenotype"]["HPOId"],),
            )
            phenotype_id = cur.fetchone()
            if phenotype_id:
                assert phenotype["Phenotype"]["HPOTerm"] == phenotype_id[1]
                phenotype_id = phenotype_id[0]
            else:
                cur.execute(
                    """
                    INSERT INTO orphanet.phenotypes (hpo_id, hpo_term)
                    VALUES (%s, %s)
                    RETURNING id
                    """,
                    (phenotype["Phenotype"]["HPOId"], phenotype["Phenotype"]["HPOTerm"]),
                )
                phenotype_id = cur.fetchone()[0]

            cur.execute(
                """
                INSERT INTO orphanet.orphapackets_phenotypes (orphacode, phenotype_id, hpo_frequency)
                VALUES (%s, %s, %s)
                """,
                (orphacode, phenotype_id, phenotype["Phenotype"]["HPOFrequency"]),
            )
        orphapacket.pop("Phenotypes")

    if "TextSection" in orphapacket:
        text_section = orphapacket["TextSection"]
        cur.execute(
            """
            INSERT INTO orphanet.text_sections (orphacode, text_section_type, contents)
            VALUES (%s, %s, %s)
            """,
            (orphacode, text_section["TextSectionType"], text_section["Contents"]),
        )
        orphapacket.pop("TextSection")

    if "AverageAgeOfOnsets" in orphapacket:
        if type(orphapacket["AverageAgeOfOnsets"]) is not list:
            items = orphapacket["AverageAgeOfOnsets"]["AverageAgeOfOnset"]
            assert len(items) == 1
            orphapacket["AverageAgeOfOnsets"] = [{"AverageAgeOfOnset": items[0]}]

        for age in orphapacket["AverageAgeOfOnsets"]:
            cur.execute(
                """
                INSERT INTO orphanet.average_age_of_onsets (orphacode, value)
                VALUES (%s, %s)
                """,
                (orphacode, age["AverageAgeOfOnset"]["value"]),
            )
        orphapacket.pop("AverageAgeOfOnsets")

    if "TypeOfInheritances" in orphapacket:
        if type(orphapacket["TypeOfInheritances"]) is not list:
            items = orphapacket["TypeOfInheritances"]["TypeOfInheritance"]
            assert len(items) == 1
            orphapacket["TypeOfInheritances"] = [{"TypeOfInheritance": items[0]}]
        for inheritance in orphapacket["TypeOfInheritances"]:
            if "TypeOfInheritance" in inheritance:
                inheritance = inheritance["TypeOfInheritance"]
            cur.execute(
                """
                INSERT INTO orphanet.type_of_inheritances (orphacode, value)
                VALUES (%s, %s)
                """,
                (orphacode, inheritance["value"]),
            )
        orphapacket.pop("TypeOfInheritances")

    if "Prevalences" in orphapacket:
        if type(orphapacket["Prevalences"]) is not list:
            items = orphapacket["Prevalences"]["Prevalence"]
            assert len(items) == 1
            orphapacket["Prevalences"] = [{"Prevalence": items[0]}]
        for prevalence in orphapacket["Prevalences"]:
            prevalence_data = prevalence["Prevalence"]
            cur.execute(
                """
                INSERT INTO orphanet.prevalences (orphacode, source, prevalence_type, prevalence_qualification, prevalence_class, val_moy, prevalence_geographic)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    orphacode,
                    prevalence_data["Source"],
                    prevalence_data["PrevalenceType"],
                    prevalence_data["PrevalenceQualification"],
                    prevalence_data["PrevalenceClass"],
                    prevalence_data["ValMoy"],
                    prevalence_data["PrevalenceGeographic"],
                ),
            )
        orphapacket.pop("Prevalences")

    conn.commit()


with alive_bar(len(os.listdir("json")), title="Importing Orphapackets") as bar:
    for filename in os.listdir("json"):
        if filename.endswith(".json"):
            with open("json/" + filename) as f:
                data = json.load(f)
                insert_from_data(data)
                bar()


def connect_parents(data):
    orphapacket = data["Orphapacket"]
    orphacode = orphapacket["ORPHAcode"]

    if "Parents" not in orphapacket:
        orphapacket["Parents"] = []

    if type(orphapacket["Parents"]) is not list:
        orphapacket["Parents"] = [orphapacket["Parents"]]

    for parent in orphapacket.get("Parents", []):
        if "Parent" in parent:
            parent = parent["Parent"]

        for parent_entry in parent:
            parent_orphacode = parent_entry["ORPHAcode"]

            cur.execute("SELECT orphacode FROM orphanet.orphapackets WHERE orphacode = %s", (parent_orphacode,))
            if not cur.fetchone():
                cur.execute(
                    """
                    INSERT INTO orphanet.orphapackets (orphacode, label)
                    VALUES (%s, %s)
                    """,
                    (parent_orphacode, parent_entry["Label"]),
                )

            cur.execute(
                """
                INSERT INTO orphanet.parent_child (parent_orphacode, child_orphacode)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING
                """,
                (parent_orphacode, orphacode),
            )

    if "Children" in orphapacket:
        for child in orphapacket.get("Children", []):
            for child_entry in child["Child"]:
                child_orphacode = child_entry["ORPHAcode"]
                cur.execute(
                    """
                    INSERT INTO orphanet.orphapackets_parents (parent_orphacode, child_orphacode)
                    VALUES (%s, %s)
                    ON CONFLICT DO NOTHING
                    """,
                    (orphacode, child_orphacode),
                )

    conn.commit()


with alive_bar(len(os.listdir("json")), title="Connecting Orphapackets") as bar:
    for filename in os.listdir("json"):
        if filename.endswith(".json"):
            with open("json/" + filename) as f:
                data = json.load(f)
                connect_parents(data)
                bar()

cur.close()
conn.close()
