-- ============================================================
--  UBIMIA - Prueba Técnica SQL
--  Script completo en orden de ejecución
-- ============================================================


-- ============================================================
--  A: TABLAS STAGING (importación de datos crudos)
-- ============================================================

IF OBJECT_ID('dbo.ClientesStg', 'U') IS NOT NULL DROP TABLE dbo.ClientesStg;
CREATE TABLE dbo.ClientesStg (
    ClienteIdRaw        VARCHAR(50) NULL,
    IngresosRaw         VARCHAR(50) NULL,
    FechaNacimientoRaw  VARCHAR(50) NULL,
    D1 VARCHAR(50) NULL,
    D2 VARCHAR(50) NULL,
    D3 VARCHAR(50) NULL
);

IF OBJECT_ID('dbo.TransaccionesStg', 'U') IS NOT NULL DROP TABLE dbo.TransaccionesStg;
CREATE TABLE dbo.TransaccionesStg (
    ClienteIdRaw            VARCHAR(50) NULL,
    ValorRaw                VARCHAR(50) NULL,
    FechaTRNRaw             VARCHAR(50) NULL,
    CantidadDeProductosRaw  VARCHAR(50) NULL,
    D1 VARCHAR(50) NULL
);

-- BULK INSERT - ajustar la ruta al environment
BULK INSERT dbo.ClientesStg
FROM 'C:\Users\ffern\Desktop\Clientes.csv'
WITH (
    FIRSTROW       = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR  = '0x0d0a',
    TABLOCK,
    CODEPAGE       = '65001'
);

-- Limpiar el ; que BULK INSERT pega al último campo
UPDATE dbo.TransaccionesStg
SET CantidadDeProductosRaw = REPLACE(CantidadDeProductosRaw, ';', '');

BULK INSERT dbo.TransaccionesStg
FROM 'C:\Users\ffern\Desktop\Transacciones.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR   = '0x0d0a',
    TABLOCK,
    CODEPAGE        = '65001'
);

UPDATE dbo.TransaccionesStg
SET CantidadDeProductosRaw = REPLACE(CantidadDeProductosRaw, ';', '');


-- ============================================================
--  PARTE B: TABLAS DEFINITIVAS
-- ============================================================

IF OBJECT_ID('dbo.ResumenTransacciones', 'U') IS NOT NULL DROP TABLE dbo.ResumenTransacciones;
IF OBJECT_ID('dbo.Transacciones',        'U') IS NOT NULL DROP TABLE dbo.Transacciones;
IF OBJECT_ID('dbo.Clientes',             'U') IS NOT NULL DROP TABLE dbo.Clientes;

CREATE TABLE dbo.Clientes (
    ClienteId       INT    NOT NULL  PRIMARY KEY,
    Ingresos        BIGINT NOT NULL,
    FechaNacimiento DATE   NULL   -- NULL permitido: clientes con fecha inválida pero con transacciones reales
);

CREATE TABLE dbo.Transacciones (
    TransaccionId        INT   IDENTITY(1,1) NOT NULL  PRIMARY KEY,
    ClienteId            INT   NOT NULL,
    Valor                BIGINT NOT NULL,
    FechaTRN             DATE   NOT NULL,
    CantidadDeProductos  INT    NOT NULL,
    CONSTRAINT FK_Transacciones_Clientes
        FOREIGN KEY (ClienteId) REFERENCES dbo.Clientes(ClienteId)
);


-- ============================================================
--  PARTE C: INSERT CON DEPURACIÓN
-- ============================================================

-- ----------------------------
--  INSERT Clientes depurado
-- ----------------------------
-- Función auxiliar para limpiar el campo Ingresos: quita $, puntos y espacios
-- Ejemplo: ' $ 4.601.721 ' -> '4601721' -> 4601721

INSERT INTO dbo.Clientes (ClienteId, Ingresos, FechaNacimiento)
SELECT
    CAST(TRIM(ClienteIdRaw) AS INT),
    CAST(REPLACE(REPLACE(REPLACE(TRIM(IngresosRaw), '$', ''), '.', ''), ' ', '') AS BIGINT),
    -- DEPURACIÓN 2 y 3: Fechas inválidas se almacenan como NULL en vez de excluir
    --   el registro, para no perder clientes que tengan transacciones reales.
    --   - ClienteId 25: año 1900 (más de 125 años, error de carga)
    --   - ClienteId 51: año 2030 (fecha futura, imposible como nacimiento)
    CASE
        WHEN CONVERT(DATE, TRIM(FechaNacimientoRaw), 103) > '1910-01-01'
         AND CONVERT(DATE, TRIM(FechaNacimientoRaw), 103) < CAST(GETDATE() AS DATE)
        THEN CONVERT(DATE, TRIM(FechaNacimientoRaw), 103)
        ELSE NULL
    END
FROM dbo.ClientesStg

-- DEPURACIÓN 1: Duplicados ClienteId 55 y 98.
--   Ambos IDs aparecen dos veces con datos distintos (ingresos y fecha de nacimiento).
--   Criterio: se conserva el registro con mayor ingreso por ser el valor más
--   representativo del cliente, el duplicado con menor ingreso se descarta.
WHERE CAST(TRIM(ClienteIdRaw) AS INT) NOT IN (55, 98);

-- Insertar los duplicados conservando solo el de mayor ingreso
INSERT INTO dbo.Clientes (ClienteId, Ingresos, FechaNacimiento)
SELECT
    CAST(TRIM(ClienteIdRaw) AS INT),
    CAST(REPLACE(REPLACE(REPLACE(TRIM(IngresosRaw), '$', ''), '.', ''), ' ', '') AS BIGINT),
    CONVERT(DATE, TRIM(FechaNacimientoRaw), 103)
FROM dbo.ClientesStg
WHERE CAST(TRIM(ClienteIdRaw) AS INT) IN (55, 98)
  AND CAST(REPLACE(REPLACE(REPLACE(TRIM(IngresosRaw), '$', ''), '.', ''), ' ', '') AS BIGINT) = (
      SELECT MAX(CAST(REPLACE(REPLACE(REPLACE(TRIM(s2.IngresosRaw), '$', ''), '.', ''), ' ', '') AS BIGINT))
      FROM dbo.ClientesStg s2
      WHERE TRIM(s2.ClienteIdRaw) = TRIM(ClientesStg.ClienteIdRaw)
  );


-- ----------------------------
--  INSERT Transacciones depurado
-- ----------------------------
INSERT INTO dbo.Transacciones (ClienteId, Valor, FechaTRN, CantidadDeProductos)
SELECT
    CAST(TRIM(ClienteIdRaw)           AS INT),
    CAST(TRIM(ValorRaw)               AS BIGINT),
    CONVERT(DATE, TRIM(FechaTRNRaw), 103),
    CAST(TRIM(CantidadDeProductosRaw) AS INT)
FROM dbo.TransaccionesStg

-- DEPURACIÓN 4: Fechas de transacción futuras (ClienteId 63 y 26, año 2033).
--   Una transacción no puede haberse realizado en el futuro, error de carga.
WHERE CONVERT(DATE, TRIM(FechaTRNRaw), 103) <= CAST(GETDATE() AS DATE)

-- DEPURACIÓN 5: CantidadDeProductos negativa (valores -1 y -2).
--   Una cantidad de productos vendidos no puede ser negativa, error de carga.
AND CAST(TRIM(CantidadDeProductosRaw) AS INT) >= 0

-- DEPURACIÓN 6: Valor de transacción = 0 (3 registros).
--   Una compra sin valor económico no representa una transacción real.
AND CAST(TRIM(ValorRaw) AS BIGINT) > 0

-- DEPURACIÓN 7: Valor outlier extremo 999.990.000 (ClienteId 28).
--   El valor máximo del resto del dataset es ~999.681. Este registro supera
--   por mucho elpromedio, se considera error de tipeo o corrupción de datos.
AND CAST(TRIM(ValorRaw) AS BIGINT) < 10000000

-- DEPURACIÓN 8: CantidadDeProductos = 149 (ClienteId 70).
--   El resto del dataset no supera 10 productos...
AND CAST(TRIM(CantidadDeProductosRaw) AS INT) <= 20;


-- ============================================================
--  PARTE D: TABLA RESUMEN (consigna punto b.2)
-- ============================================================

CREATE TABLE dbo.ResumenTransacciones (
    ClienteId           INT    NOT NULL,
    Ingresos            BIGINT NOT NULL,
    AnioTransaccion     INT    NOT NULL,
    TotalTransacciones  INT    NOT NULL,
    ValorTotal          BIGINT NOT NULL,
    CONSTRAINT PK_Resumen
        PRIMARY KEY (ClienteId, AnioTransaccion),
    CONSTRAINT FK_Resumen_Clientes
        FOREIGN KEY (ClienteId) REFERENCES dbo.Clientes(ClienteId)
);

INSERT INTO dbo.ResumenTransacciones
    (ClienteId, Ingresos, AnioTransaccion, TotalTransacciones, ValorTotal)
SELECT
    t.ClienteId,
    c.Ingresos,
    YEAR(t.FechaTRN)    AS AnioTransaccion,
    COUNT(*)            AS TotalTransacciones,
    SUM(t.Valor)        AS ValorTotal
FROM dbo.Transacciones t
INNER JOIN dbo.Clientes c ON t.ClienteId = c.ClienteId
GROUP BY t.ClienteId, c.Ingresos, YEAR(t.FechaTRN)
ORDER BY t.ClienteId, YEAR(t.FechaTRN);


-- ============================================================
--  VERIFICACIÓN FINAL
-- ============================================================

SELECT 'Clientes'             AS Tabla, COUNT(*) AS Registros FROM dbo.Clientes
UNION ALL
SELECT 'Transacciones',                 COUNT(*)              FROM dbo.Transacciones
UNION ALL
SELECT 'ResumenTransacciones',          COUNT(*)              FROM dbo.ResumenTransacciones;

SELECT * FROM dbo.ResumenTransacciones ORDER BY ClienteId, AnioTransaccion;