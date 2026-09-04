Modelo_Relacional_Spin.sql

-- 1. Catálogo de Clientes
CREATE TABLE Dim_Cliente (
    ID_Cliente VARCHAR(50) NOT NULL PRIMARY KEY,
    RFC VARCHAR(13) NOT NULL,
    Nombre_Cliente VARCHAR(150) NOT NULL,
    Fecha_Alta DATETIME DEFAULT GETDATE()
);

-- 2. Catálogo de Productos Financieros
CREATE TABLE Dim_Producto (
    ID_Producto INT IDENTITY(1,1) PRIMARY KEY,
    Loan_Name VARCHAR(100) NOT NULL,
    Frecuencia VARCHAR(20) NOT NULL CHECK (Frecuencia IN ('SEMANAL', 'QUINCENAL', 'MENSUAL')),
    Plazo INT NOT NULL
);

-- 3. Tabla Paramétrica de UMAs por Fecha
CREATE TABLE Dim_Calendario_UMA (
    Fecha DATE NOT NULL PRIMARY KEY,
    Anio INT NOT NULL,
    Valor_UMA_Diario DECIMAL(10,2) NOT NULL,
    Umbral_Aviso_Pesos AS (Valor_UMA_Diario * 1605.0) PERSISTED
);

-- 4. Tabla de Hechos: Transacciones de Crédito
CREATE TABLE Fact_Creditos (
    Folio VARCHAR(50) NOT NULL PRIMARY KEY,
    ID_Cliente VARCHAR(50) NOT NULL,
    ID_Producto INT NOT NULL,
    Fecha_Solicitud DATE NULL,
    Fecha_Deposito DATE NULL,
    Fecha_Primer_Pago DATE NULL,
    Monto DECIMAL(18,2) NULL,
    Cuota DECIMAL(18,2) NULL,
    Tasa_Con_Impuesto DECIMAL(6,2) NULL,
    Tasa_Sin_Impuesto DECIMAL(6,2) NULL,
    Status VARCHAR(30) NOT NULL,
    Estatus_Cobranza VARCHAR(30) NOT NULL,
    Registro_Valido BIT NOT NULL DEFAULT 1,
    Motivo_Inconsistencia VARCHAR(255) NULL,
    CONSTRAINT FK_Credito_Cliente FOREIGN KEY (ID_Cliente) REFERENCES Dim_Cliente(ID_Cliente),
    CONSTRAINT FK_Credito_Producto FOREIGN KEY (ID_Producto) REFERENCES Dim_Producto(ID_Producto)
);

-- 5. Tabla de Hechos: Auditoría y Acumulación LFPIORPI
CREATE TABLE Fact_Auditoria_LFPIORPI (
    ID_Auditoria BIGINT IDENTITY(1,1) PRIMARY KEY,
    Folio VARCHAR(50) NOT NULL UNIQUE,
    Monto_UMAs DECIMAL(14,4) NOT NULL,
    Acumulado_6M_Pesos DECIMAL(18,2) NOT NULL,
    Acumulado_6M_UMAs DECIMAL(14,4) NOT NULL,
    Porcentaje_Umbral DECIMAL(6,2) NOT NULL,
    Nivel_Alerta VARCHAR(50) NOT NULL,
    Requiere_Aviso_SAT BIT NOT NULL,
    Fecha_Auditoria DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Auditoria_Credito FOREIGN KEY (Folio) REFERENCES Fact_Creditos(Folio)
);
