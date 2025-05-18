DROP TABLE IF EXISTS desembarques CASCADE;

DROP TABLE IF EXISTS puerto CASCADE;

DROP TABLE IF EXISTS departamento CASCADE;

DROP TABLE IF EXISTS provincia CASCADE;

DROP TABLE IF EXISTS especie CASCADE;

DROP TABLE IF EXISTS especie_agrupada CASCADE;

DROP TABLE IF EXISTS desembarques_temporal CASCADE;

CREATE TABLE desembarques_temporal (
    fecha TEXT,
    flota TEXT,
    puerto TEXT,
    provincia TEXT,
    provincia_id TEXT,
    departamento TEXT,
    departamento_id TEXT,
    latitud TEXT,
    longitud TEXT,
    categoria TEXT,
    especie TEXT,
    especie_agrupada TEXT,
    captura TEXT
);

CREATE TABLE public.provincia (
    id_provincia TEXT PRIMARY KEY,
    nombre_provincia VARCHAR(100) UNIQUE
);

CREATE TABLE public.departamento (
    id_departamento TEXT PRIMARY KEY,
    nombre_departamento VARCHAR(100) UNIQUE,
    id_provincia TEXT REFERENCES provincia (id_provincia)
);

CREATE TABLE public.puerto (
    id_puerto SERIAL PRIMARY KEY,
    nombre VARCHAR(75) UNIQUE,
    latitud NUMERIC(10, 6),
    longitud NUMERIC(10, 6),
    id_departamento TEXT REFERENCES departamento (id_departamento)
);

CREATE TABLE public.especie_agrupada (
    id_especie_agrupada SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE public.especie (
    id_especie SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    id_especie_agrupada INTEGER REFERENCES especie_agrupada (id_especie_agrupada)
);

CREATE TABLE public.desembarques (
    id SERIAL PRIMARY KEY,
    fecha TEXT,
    flota VARCHAR(50),
    id_puerto INTEGER REFERENCES puerto (id_puerto), --La tabla puerto incluye referencia a provincia, departamento y coordenadas 
    categoria VARCHAR(30),
    id_especie INTEGER REFERENCES especie (id_especie), ---La tabla especie incluye referencia a especie agrupada
    captura INTEGER
);

COPY desembarques_temporal
FROM '/archivo.csv' DELIMITER ',' CSV HEADER;

--JOIN

INSERT INTO
    provincia (
        id_provincia,
        nombre_provincia
    )
SELECT DISTINCT
    provincia_id,
    provincia
FROM desembarques_temporal
WHERE
    provincia IS NOT NULL;

INSERT INTO
    departamento (
        id_departamento,
        nombre_departamento,
        id_provincia
    )
SELECT DISTINCT
    dt.departamento AS id_departamento,
    dt.departamento AS nombre_departamento,
    p.id_provincia
FROM
    desembarques_temporal dt
    JOIN provincia p ON dt.provincia = p.nombre_provincia
WHERE
    dt.departamento IS NOT NULL
    AND dt.provincia IS NOT NULL;

INSERT INTO puerto (nombre, latitud, longitud, id_departamento)
SELECT DISTINCT
    dt.puerto,
    dt.latitud::numeric,
    dt.longitud::numeric,
    d.id_departamento
FROM desembarques_temporal dt
JOIN departamento d ON dt.departamento = d.nombre_departamento
WHERE dt.puerto IS NOT NULL;

INSERT INTO
    especie_agrupada (nombre)
SELECT DISTINCT
    especie_agrupada
FROM desembarques_temporal
WHERE
    especie_agrupada IS NOT NULL;

INSERT INTO
    especie (nombre, id_especie_agrupada)
SELECT DISTINCT
    dt.especie,
    ea.id_especie_agrupada
FROM
    desembarques_temporal dt
    JOIN especie_agrupada ea ON dt.especie_agrupada = ea.nombre
WHERE
    dt.especie IS NOT NULL ON CONFLICT (nombre) DO NOTHING;

INSERT INTO desembarques (
    fecha, flota, id_puerto, categoria, id_especie, captura
)
SELECT
    dr.fecha,
    dr.flota,
    p.id_puerto,
    dr.categoria,
    e.id_especie,
    dr.captura::integer
FROM desembarques_temporal dr
JOIN puerto p ON dr.puerto = p.nombre
JOIN especie e ON dr.especie = e.nombre;

--SELECT d.id,d.fecha,d.flota,d.captura,p.nombre AS nombre_puertoFROM desembarques d JOIN puerto p ON d.id_puerto = p.id_puerto