-- =========================================================
-- 1. CONFIGURACIÓN DEL ESQUEMA
-- =========================================================
CREATE SCHEMA IF NOT EXISTS proyecto_final;
SET search_path TO proyecto_final, public;


--TRUNCATE TABLE proyecto_final.dim_garantias CASCADE;
--TRUNCATE TABLE proyecto_final.dim_productos CASCADE;
--TRUNCATE TABLE proyecto_final.dim_destinos CASCADE;
--TRUNCATE TABLE proyecto_final.primas CASCADE;
--TRUNCATE TABLE proyecto_final.siniestros CASCADE;


DROP TABLE IF EXISTS proyecto_final.siniestros                       CASCADE;
DROP TABLE IF EXISTS proyecto_final.primas                           CASCADE;
DROP TABLE IF EXISTS proyecto_final.dim_productos                    CASCADE;
DROP TABLE IF EXISTS proyecto_final.dim_destinos                     CASCADE;
DROP TABLE IF EXISTS proyecto_final.dim_garantias                    CASCADE;

-- =========================================================
-- 1. TABLAS DE DIMENSIONES
-- =========================================================

CREATE TABLE proyecto_final.dim_productos (
    nueva_formula                                    VARCHAR(100)    PRIMARY KEY,
    nom_cliente                                      VARCHAR(100)    NOT NULL,
    nom_formula_detalle                              VARCHAR(100)    NOT NULL,
    union_form_codigo                                VARCHAR(100)    NOT NULL,
    nom_formula                                      VARCHAR(100)    NOT NULL,
    agrupacion                                       VARCHAR(50)     NOT NULL,
    tipo_canal                                       VARCHAR(50)     NOT NULL,
    tipo_seguro                                      VARCHAR(50)     NOT NULL
);


CREATE TABLE proyecto_final.dim_destinos (
    city_insured                                     VARCHAR(100)    PRIMARY KEY,
    destino_final                                    VARCHAR(100)    NOT NULL
);



CREATE TABLE proyecto_final.dim_garantias (
    nom_cause_d_intervention                         VARCHAR(255),
    nom_detail_caused_intervention                   VARCHAR(255),
    garantia                                         VARCHAR(255),
    concatenacion_gar                                VARCHAR(101)    PRIMARY KEY,
    agrupacion_1                                     VARCHAR(255)    NOT NULL,
    agrupacion_2                                     VARCHAR(255)    NOT NULL
);



-- =========================================================
-- 2. TABLAS DE HECHOS 
-- =========================================================
CREATE TABLE proyecto_final.primas (
    policy_number                                    VARCHAR(50)     NOT NULL,
    number_insured                                   INTEGER         NOT NULL,
    product                                          VARCHAR(100)    NOT NULL,
    client                                           VARCHAR(3)      NOT null,
    policy_client                                    VARCHAR(50)     PRIMARY key    NOT NULL,
    policy_start_date                                DATE            NOT NULL,
    policy_start_date_travel                         DATE            NOT NULL,
    end_travel                                       DATE            NOT NULL,
    duracion_viaje                                   INTEGER         NOT null      CHECK (duracion_viaje >= 0),
    city_insured                                     VARCHAR(100)    NOT NULL,
    gross_written_premium                            NUMERIC         NOT NULL,
    taxes                                            NUMERIC,
    comision                                         NUMERIC,
    policy_status                                    VARCHAR(50),
    billing_month                                    INTEGER,
    anio_contable                                    VARCHAR(50),
    dias_contrato                                    INTEGER                       CHECK (dias_contrato >= 0),
    ppnc                                             NUMERIC(5, 4)   NOT NULL
);




-- =========================================================
--  3. TABLAS DE DIMENSIONES
-- =========================================================


CREATE TABLE proyecto_final.siniestros (
    expediente                                       VARCHAR(50)      NOT NULL,    
    mandato                                          VARCHAR(50),
    policy_number                                    VARCHAR(50)      NOT NULL,
    client                                           VARCHAR(3)       NOT NULL,
    policy_client                                    VARCHAR(50)      NOT NULL,          
    fecha_apertura                                   DATE             NOT NULL,
    loss_country                                     VARCHAR(50), 
    nom_cause_d_intervention                         VARCHAR(255),
    nom_detail_cause_d_intervention                  VARCHAR(255),
    garantia                                         VARCHAR(255),
    medio                                            VARCHAR(255),
    concatenacion_gar                                VARCHAR(101),
    coste_eur                                        DECIMAL(15, 2),
    libelle_segmentation_cge                         VARCHAR(255),
    num_dossier                                      INTEGER           CHECK (num_dossier >= 0),
    num_dossier_gar                                  INTEGER           CHECK (num_dossier_gar >= 0),
    num_dossier_gar_detalle                          INTEGER           CHECK (num_dossier_gar_detalle >= 0),
);

-- =========================================================
-- 4. CARGA DE DATOS
-- =========================================================
COPY proyecto_final.dim_destinos FROM 'C:\PROYECTO_FINAL\dim_destinos.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';');
COPY proyecto_final.dim_productos FROM 'C:\PROYECTO_FINAL\dim_productos.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';');
COPY proyecto_final.primas FROM 'C:\PROYECTO_FINAL\primas.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';');
COPY proyecto_final.dim_garantias FROM 'C:\PROYECTO_FINAL\dim_garantias.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';');

COPY proyecto_final.siniestros FROM 'C:\PROYECTO_FINAL\dim_siniestros.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';');



-- =========================================================
-- 5. RELACIONES (FOREIGN KEYS)
-- =========================================================


-- Primas a Productos (Uno a muchos)
ALTER TABLE proyecto_final.primas 
ADD CONSTRAINT fk_primas_productos 
FOREIGN KEY (product) REFERENCES proyecto_final.dim_productos(nueva_formula);

-- Primas a Destinos (Uno a muchos)
ALTER TABLE proyecto_final.primas 
ADD CONSTRAINT fk_primas_destinos 
FOREIGN KEY (city_insured) REFERENCES proyecto_final.dim_destinos(city_insured);

-- Siniestros a Garantías (Uno a muchos)
ALTER TABLE proyecto_final.siniestros 
ADD CONSTRAINT fk_siniestros_garantias 
FOREIGN KEY (concatenacion_gar) REFERENCES proyecto_final.dim_garantias(concatenacion_gar);

-- Siniestros a Primas (Uno a muchos)
-- Nota: Unimos por policy_client porque es el valor único en Primas
ALTER TABLE proyecto_final.siniestros 
ADD CONSTRAINT fk_siniestros_primas 
FOREIGN KEY (policy_client) REFERENCES proyecto_final.primas(policy_client);


---- Creo las nuevas columnas para calculos siguientes ----

ALTER TABLE proyecto_final.primas 
ADD COLUMN Prima_sin_impuesto_sin_com NUMERIC(15, 2) GENERATED ALWAYS AS (Gross_written_premium - Taxes - Comision) STORED,
ADD COLUMN Prima_neta NUMERIC(15, 2) GENERATED ALWAYS AS (Gross_written_premium - Taxes) STORED,
ADD COLUMN PPNC_montante NUMERIC(15, 2) GENERATED ALWAYS AS ((Gross_written_premium - Taxes ) * PPNC) STORED,
ADD COLUMN Prima_adquirida NUMERIC(15, 2) GENERATED ALWAYS AS ((Gross_written_premium - Taxes ) * (1- PPNC)) STORED,
ADD COLUMN Aseg_adquiridos NUMERIC(15, 2) GENERATED ALWAYS AS ( number_insured * (1-PPNC)) STORED;

---- Creo resto de columnas para mejor analisis ----

ALTER TABLE proyecto_final.siniestros
ADD COLUMN anio_apertura INT GENERATED ALWAYS AS (EXTRACT(YEAR FROM Fecha_apertura)) STORED,
ADD COLUMN mes_apertura INT GENERATED ALWAYS AS (EXTRACT(MONTH FROM Fecha_apertura)) STORED;


ALTER TABLE proyecto_final.primas
ADD COLUMN anio_compra INT GENERATED ALWAYS AS (EXTRACT(YEAR FROM policy_start_date)) STORED,
ADD COLUMN mes_compra INT GENERATED ALWAYS AS (EXTRACT(MONTH FROM policy_start_date)) STORED,
ADD COLUMN anio_inicio_viaje INT GENERATED ALWAYS AS (EXTRACT(YEAR FROM policy_start_date_Travel)) STORED,
ADD COLUMN mes_inicio_viaje INT GENERATED ALWAYS AS (EXTRACT(MONTH FROM policy_start_date_Travel)) STORED,
ADD COLUMN anio_fin_viaje INT GENERATED ALWAYS AS (EXTRACT(YEAR FROM End_Travel)) STORED,
ADD COLUMN mes_fin_viaje INT GENERATED ALWAYS AS (EXTRACT(MONTH FROM End_Travel)) STORED;





SELECT SUM(gross_written_premium) AS total_prima_bruta
FROM proyecto_final.primas;


SELECT SUM(coste_eur) AS total_siniestros
FROM proyecto_final.siniestros;



