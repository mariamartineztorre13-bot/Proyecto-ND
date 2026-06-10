CREATE SCHEMA IF NOT EXISTS analiticas;

-- Limpiamos las vistas anteriores si existen
DROP VIEW IF EXISTS analiticas.v_fact_primas_con_costes;
DROP VIEW IF EXISTS analiticas.v_siniestros_enriquecidos;
DROP TABLE IF EXISTS analiticas.v_dim_calendario;

-- 1. Vista: Primas con Costes

CREATE OR REPLACE VIEW analiticas.v_fact_primas_con_costes AS
SELECT 
    -- Datos de Póliza
    p.policy_number, p.number_insured, p.Aseg_adquiridos, p.product, p.client, p.policy_client,
    p.policy_start_date, p.policy_start_date_travel, p.end_travel, p.duracion_viaje,
    p.city_insured, 
    dd.destino_final, -- Columna traída de la tabla de destinos
    p.gross_written_premium, p.taxes, p.comision, p.policy_status,
    p.billing_month, p.dias_contrato, p.ppnc,
    p.Prima_sin_impuesto_sin_com, p.Prima_neta, p.PPNC_montante, p.Prima_adquirida,
    p.anio_compra, p.mes_compra, p.anio_inicio_viaje, p.mes_inicio_viaje, p.anio_fin_viaje, p.mes_fin_viaje,
    
    -- Datos de la dimensión de productos
    dp.nom_cliente, dp.nom_formula_detalle, dp.union_form_codigo, dp.nom_formula,
    dp.agrupacion, dp.tipo_canal, dp.tipo_seguro,
    
    -- Cálculos de siniestralidad (Agregados por póliza)
    COALESCE(s.total_coste_siniestros, 0) AS total_coste_siniestros,
    COALESCE(s.total_dossier, 0) AS total_dossier,
    
    -- Cálculos de rentabilidad
    (p.Prima_adquirida - COALESCE(s.total_coste_siniestros, 0)) AS margen_sin_comision,
    (p.Prima_adquirida - COALESCE(s.total_coste_siniestros, 0) - COALESCE(p.comision, 0)) AS margen_neto_real,
    
    -- Clasificación
    CASE 
        WHEN COALESCE(s.total_dossier, 0) = 0 THEN 'Sin siniestros'
        ELSE 'Con siniestros'
    END AS estado_siniestros

FROM proyecto_final.primas p
-- Join con Productos
LEFT JOIN proyecto_final.dim_productos dp ON p.product = dp.nueva_formula
-- Join con Destinos (basado en tu FK: p.city_insured = dd.city_insured)
LEFT JOIN proyecto_final.dim_destinos dd ON p.city_insured = dd.city_insured
-- Join con el subquery de siniestros
LEFT JOIN (
    SELECT 
        policy_client, 
        SUM(coste_eur) AS total_coste_siniestros, 
        SUM(num_dossier) AS total_dossier
    FROM proyecto_final.siniestros
    GROUP BY policy_client
) s ON p.policy_client = s.policy_client;

-- 2. Vista: Calendario (Aquí mantenemos tabla porque no depende de datos externos cambiantes)

Para lograr que tu vista analiticas.v_siniestros_enriquecidos sea precisa y solo traiga la información necesaria (específicamente el destino_final vinculado a la póliza), el código que tienes es casi correcto, pero tiene un pequeño conflicto: estás seleccionando p.destino_final (que no existe en tu tabla primas) y luego intentando traer d.destino_final mediante el JOIN.

Aquí tienes la versión corregida y limpia:


CREATE OR REPLACE VIEW analiticas.v_siniestros_enriquecidos AS
SELECT 
    -- Datos principales del siniestro
    s.*,
    -- Datos seleccionados de la póliza
    p.number_insured,p.Aseg_adquiridos,p.product,
    p.policy_start_date,p.policy_start_date_travel, 
    p.end_travel, p.duracion_viaje, p.dias_contrato, 
    p.anio_compra,p.mes_compra, 
    p.anio_inicio_viaje,p.mes_inicio_viaje,
    p.anio_fin_viaje, p.mes_fin_viaje,
    -- Datos de la dimensión de productos
    prod.nom_cliente, prod.nom_formula_detalle,
    prod.union_form_codigo,prod.nom_formula, 
    prod.agrupacion,prod.tipo_canal, prod.tipo_seguro,
    -- Datos de destino (solo el valor limpio de la dimensión)
    d.destino_final,
    g.agrupacion_1,
    g.agrupacion_2
    
FROM proyecto_final.siniestros s
LEFT JOIN proyecto_final.primas p ON s.policy_client = p.policy_client
LEFT JOIN proyecto_final.dim_productos prod ON p.product = prod.nueva_formula
LEFT JOIN proyecto_final.dim_destinos d ON p.city_insured = d.city_insured
LEFT JOIN proyecto_final.dim_garantias g ON s.concatenacion_gar = g.concatenacion_gar;


-- 3. Vista: Calendario (Aquí mantenemos tabla porque no depende de datos externos cambiantes)
-- (Para el calendario, dejarlo como tabla es correcto porque es estático)


CREATE TABLE analiticas.v_dim_calendario AS
SELECT 
    fecha::date AS fecha,
    EXTRACT(YEAR FROM fecha)::int AS anio,
    EXTRACT(MONTH FROM fecha)::int AS mes,
    CASE EXTRACT(MONTH FROM fecha)
        WHEN 1 THEN 'Enero' WHEN 2 THEN 'Febrero' WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril' WHEN 5 THEN 'Mayo' WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio' WHEN 8 THEN 'Agosto' WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
    END AS nombre_mes,
    EXTRACT(QUARTER FROM fecha)::int AS trimestre
FROM GENERATE_SERIES('2023-01-01'::date, '2026-12-31'::date, '1 day'::interval) AS fecha;
ALTER TABLE analiticas.v_dim_calendario ADD PRIMARY KEY (fecha);








SELECT 'Originales' as fuente, SUM(p.gross_written_premium) as prima, SUM(s.coste_eur) as coste, SUM(s.num_dossier) as montante_dossier
FROM proyecto_final.primas p
LEFT JOIN proyecto_final.siniestros s ON p.policy_client = s.policy_client

UNION ALL

-- Totales en tu vista
SELECT 'Vista' as fuente, SUM(gross_written_premium ), SUM(total_coste_siniestros), SUM(total_siniestros)
FROM analiticas.v_fact_primas_con_costes;






SELECT 
    SUM(gross_written_premium) AS total_primas_neta,
    SUM(Prima_adquirida) AS total_primas_neta,
    SUM(number_insured) AS total_asegurados,
    SUM(total_dossier) AS total_dossiers_montante,
    SUM(total_coste_siniestros) AS total_dossiers_montante

FROM analiticas.v_fact_primas_con_costes;


SELECT 
    SUM(coste_eur) AS total_primas_neta,
    SUM(number_insured) AS total_asegurados,
    SUM(num_dossier) AS total_dossiers_montante

FROM analiticas.v_siniestros_enriquecidos;



