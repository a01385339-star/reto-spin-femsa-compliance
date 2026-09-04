<div align="center">

# 🛡️ Sistema de Monitoreo Automatizado y Cumplimiento LFPIORPI para Spin Crédito
### Detección de Fraccionamiento de Operaciones y Alertamiento Preventivo ante el SAT

[![Status](https://img.shields.io/badge/Estatus-Entregable%20Final-brightgreen?style=for-the-badge)](#-resumen-ejecutivo)
[![Org](https://img.shields.io/badge/Organizaci%C3%B3n-Spin%20by%20OXXO%20%7C%20FEMSA%20Digital-EE0000?style=for-the-badge)](https://spinbyoxxo.com.mx/)
[![Legal](https://img.shields.io/badge/Marco%20Legal-Spin%20T%26C%20%2F%20LFPIORPI-0052CC?style=for-the-badge)](https://spinbyoxxo.com.mx/terminos-y-condiciones/)
[![SQL](https://img.shields.io/badge/SQL-Modelo%20Relacional%203FN-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)](./Modelo_Relacional_Spin.sql)
[![Python](https://img.shields.io/badge/Notebook-Jupyter%20%2F%20Colab-3776AB?style=for-the-badge&logo=python&logoColor=white)](./borrador-2.ipynb)
[![Dataset](https://img.shields.io/badge/Data-CSV%20Limpio-239120?style=for-the-badge&logo=apachespark&logoColor=white)](./Base_Operaciones_Credito_TEC_Limpia.csv)

---

| Campo | Detalle |
|---|---|
| 👩‍💻 **Autora** | Laura Elena Mata Serrato |
| 🎓 **Programa** | Licenciatura en Inteligencia de Negocios |
| 🏛️ **Institución** | Tecnológico de Monterrey |
| 🏢 **Organización Caso de Estudio** | Spin by OXXO / FEMSA Digital |
| 📅 **Fecha** | Septiembre 2026 |
| 📌 **Estatus** | Repositorio Técnico y Metodológico  |

</div>

---

## 📋 Resumen Ejecutivo

Este repositorio documenta el diseño, la normalización relacional y la automatización de un pipeline de monitoreo para el cumplimiento estricto de la **Ley Federal para la Prevención e Identificación de Operaciones con Recursos de Procedencia Ilícita (LFPIORPI)** en Spin Crédito (FEMSA Digital). El sistema fiscaliza, mediante una ventana móvil retrospectiva de 180 días naturales, la acumulación de créditos por cliente bajo el umbral de **1,605 UMAs** para emitir avisos obligatorios ante el Servicio de Administración Tributaria (SAT). El proyecto sustituye la tabla desnormalizada original por un modelo en Tercera Forma Normal (3FN) en SQL Server y un proceso ETL automatizado en Python optimizado con Inteligencia Artificial.

---

## SECCIÓN 1: ENTENDIMIENTO DEL NEGOCIO Y RESTRICCIONES REGULATORIAS

### 1.1 Contexto Legal
Spin Crédito presta dinero a sus usuarios de manera digital. Ante la legislación mexicana (**LFPIORPI, Art. 17 Fracción IV**), el otorgamiento habitual o profesional de crédito o préstamos por entidades no bancarias es una **Actividad Vulnerable**, sujeta a obligaciones de identificación del cliente y presentación de reportes formales.

### 1.2 La Regla de Oro: Umbral de 1,605 UMAs
Si un usuario acumula préstamos por un monto igual o superior a **1,605 UMAs en un periodo de hasta 6 meses (180 días naturales)**, Spin tiene la obligación de presentar un aviso formal ante el SAT a más tardar el **día 17 del mes inmediato siguiente** a aquel en que se rebasó dicho monto.

### 1.3 El Riesgo de Evaluar Crédito por Crédito
Evaluar cada solicitud de forma aislada genera una ceguera operativa grave: un cliente que solicita microcréditos recurrentes ("créditos hormiga") no parece sospechoso en transacciones individuales, pero la suma acumulada dentro del periodo de 180 días supera el umbral legal. Sin un algoritmo con memoria histórica retrospectiva, la empresa comete omisión involuntaria de avisos.

### 1.4 Actualización y Temporalidad de la UMA
El umbral no está fijado en pesos sino en UMAs (Unidades de Medida y Actualización), cuyo valor diario oficial es actualizado cada año por el INEGI:

| Año | Valor Diario UMA | Umbral Legal de Aviso (1,605 UMAs) |
|---|---|---|
| **2024** | $108.57 MXN | $174,254.85 MXN |
| **2025** | $113.14 MXN | $181,589.70 MXN |
| **2026** | $117.31 MXN | $188,282.55 MXN |

El modelo asigna dinámicamente el valor de la UMA según el año en que se dispersó el préstamo (`Fecha_Deposito`).

### 1.5 Cálculo de Ventana Móvil (180 Días)
La ley no fiscaliza semestres de calendario fijos (ejemplo: enero a junio). El sistema evalúa una **ventana rodante de 180 días naturales** contados hacia atrás a partir de cada nueva dispersión del usuario.

### 1.6 Nuevas Variables Generadas
- `Anio_Operacion` y `Mes_Operacion`: Segmentación temporal del crédito.
- `UMA_Diaria`: Valor oficial aplicable según el año del depósito.
- `Monto_UMAs`: Monto individual convertido a unidades regulatorias.
- `Acumulado_6M_Pesos` y `Acumulado_6M_UMAs`: Saldo móvil de 180 días por cliente.
- `Porcentaje_Umbral_Aviso`: Nivel de consumo respecto a las 1,605 UMAs.
- `Nivel_Alerta` y `Requiere_Aviso_SAT`: Clasificación semafórica del riesgo.

### 1.7 Sanciones por Incumplimiento ante el SAT / UIF (Artículos 53 y 54 LFPIORPI)

| Infracción | Fundamento Legal | Sanción en UMAs | Impacto Económico (UMA 2026: $117.31) | Impacto Institucional |
|---|---|---|---|---|
| **Presentación extemporánea de avisos** | Art. 53, Fracc. II | 200 a 2,000 UMAs | **$23,462 a $234,620 MXN** | Multas acumulativas por cada crédito reportado fuera de plazo. |
| **Falta de identificación de clientes** | Art. 53, Fracc. I | 200 a 2,000 UMAs | **$23,462 a $234,620 MXN** | Observaciones formales y auditorías regulatorias. |
| **Omisión total de presentar aviso** | Art. 53, Fracc. VI | 10,000 a 65,000 UMAs | **$1.17 a $7.62 MDP** | Sanción de hasta el 100% del valor de la operación por cliente omitido. |
| **Reincidencia grave** | Art. 54 | Multas agravadas | Multas corporativas | Revocación de facultades operativas y daño reputacional de la marca Spin. |

---

## SECCIÓN 2: MODELADO RELACIONAL EN 3FN Y SQL DDL 

### ¿Por qué empezamos por el modelado en SQL?
Antes de programar cualquier línea de código en Python o intentar armar un tablero de control, el primer paso obligado fue diseñar la arquitectura de la base de datos en SQL Server. 

El archivo fuente que recibimos era una sola tabla plana donde todo venía mezclado: datos personales del cliente, condiciones del préstamo, fechas y montos. Trabajar directamente sobre un archivo así en una empresa financiera como Spin by OXXO es inviable por tres razones principales:
1. **Riesgo de inconsistencia legal:** Si un cliente cambia de domicilio, corrige su nombre o su RFC, tendríamos que actualizarlo a mano en decenas de filas distintas; si una sola fila queda desfasada, el reporte para el SAT saldría con datos contradictorios.
2. **Desperdicio de recursos e ineficiencia:** Repetir una y otra vez nombres de clientes y textos largos de productos en miles de transacciones satura el almacenamiento y alenta cualquier consulta analítica.
3. **Falta de integridad:** Un archivo plano no puede impedir que alguien capture un monto negativo, una frecuencia inexistente o que mezcle formatos.

Por estas razones, decidimos crear un **modelo relacional normalizado en Tercera Forma Normal (3FN)** dividiendo la información en entidades con un propósito único:
- **Separar lo fijo de lo transaccional:** Creamos catálogos maestros independientes para los clientes (`Dim_Cliente`) y los productos financieros (`Dim_Producto`) para que cada entidad exista una sola vez y se enlace mediante llaves cortas.
- **Parametrizar las reglas de la ley:** Diseñamos `Dim_Calendario_UMA` para que los valores oficiales de la UMA no dependan de fórmulas manuales ni queden fijos en el código, sino gobernados por fecha como exige el marco regulatorio.
- **Aislar la operación del escrutinio legal:** Separamos las operaciones del día a día (`Fact_Creditos`) de las auditorías antilavado (`Fact_Auditoria_LFPIORPI`), garantizando que los cálculos de riesgo y las banderas de reporte al SAT se resguarden en una tabla dedicada con acceso exclusivo para el área de Cumplimiento.

Este diseño establece los cimientos sobre los cuales el pipeline de Python deposita los datos de forma estructurada, escalable y con reglas de integridad respaldadas por el motor de base de datos.

### 2.1 Diagnóstico de la Base Original
La fuente transaccional contenía 10,011 registros desnormalizados en una tabla plana:
- **Redundancia:** Repetición masiva de RFCs, nombres de clientes y nombres largos de producto. Columna `folio 1` duplicada.
- **Tipos de datos mixtos:** Cifras monetarias con signos de pesos y comas conviviendo con datos decimales.
- **Registros corruptos:** 2 filas vacías que requerían aislamiento y auditoría sin borrado destructivo.

### 2.2 Arquitectura Relacional en Tercera Forma Normal (3FN)
```text
                  ┌──────────────────────┐
                  │     Dim_Cliente      │
                  ├──────────────────────┤
                  │ PK  ID_Cliente       │
                  │     RFC              │
                  │     Nombre_Cliente   │
                  └──────────┬───────────┘
                             │ 1
                             │
                             │ N
┌──────────────────┐      ┌──┴─────────────────────────┐      ┌─────────────────────────┐
│   Dim_Producto   │      │        Fact_Creditos       │      │   Dim_Calendario_UMA    │
├──────────────────┤      ├────────────────────────────┤      ├─────────────────────────┤
│ PK  ID_Producto  │1    N│ PK  Folio                  │N    1│ PK  Fecha_Deposito      │
│     Loan_Name    ├──────┤ FK  ID_Cliente             ├──────┤     Anio                │
│     Frecuencia   │      │ FK  ID_Producto            │      │     Valor_UMA_Diario    │
│     Plazo        │      │ FK  Fecha_Deposito         │      │     Umbral_Aviso_Pesos  │
└──────────────────┘      │     Monto                  │      └─────────────────────────┘
                          │     Cuota                  │
                          │     Status                 │
                          │     Registro_Valido        │
                          │     Motivo_Inconsistencia  │
                          └──────────┬─────────────────┘
                                     │ 1
                                     │
                                     │ 1
                          ┌──────────┴─────────────────┐
                          │  Fact_Auditoria_LFPIORPI   │
                          ├────────────────────────────┤
                          │ PK  ID_Auditoria           │
                          │ FK  Folio                  │
                          │     Acumulado_6M_Pesos     │
                          │     Acumulado_6M_UMAs      │
                          │     Porcentaje_Umbral      │
                          │     Nivel_Alerta           │
                          │     Requiere_Aviso_SAT     │
                          └────────────────────────────┘
```
### 2.3 Script DDL en T-SQL
```sql
DROP TABLE IF EXISTS Fact_Auditoria_LFPIORPI;
DROP TABLE IF EXISTS Fact_Creditos;
DROP TABLE IF EXISTS Dim_Calendario_UMA;
DROP TABLE IF EXISTS Dim_Producto;
DROP TABLE IF EXISTS Dim_Cliente;

CREATE TABLE Dim_Cliente (
    ID_Cliente VARCHAR(50) NOT NULL PRIMARY KEY,
    RFC VARCHAR(13) NOT NULL,
    Nombre_Cliente VARCHAR(150) NOT NULL,
    Fecha_Alta DATETIME DEFAULT GETDATE()
);

CREATE TABLE Dim_Producto (
    ID_Producto INT IDENTITY(1,1) PRIMARY KEY,
    Loan_Name VARCHAR(100) NOT NULL,
    Frecuencia VARCHAR(20) NOT NULL CHECK (Frecuencia IN ('SEMANAL', 'QUINCENAL', 'MENSUAL')),
    Plazo INT NOT NULL
);

CREATE TABLE Dim_Calendario_UMA (
    Fecha DATE NOT NULL PRIMARY KEY,
    Anio INT NOT NULL,
    Valor_UMA_Diario DECIMAL(10,2) NOT NULL,
    Umbral_Aviso_Pesos AS (Valor_UMA_Diario * 1605.0) PERSISTED
);

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
```
### 2.4 Documentación de Tablas y Sentencias DDL
- **`DROP TABLE IF EXISTS`:** Elimina las tablas en orden inverso de dependencias (hechos antes que dimensiones) para no violar restricciones de llaves foráneas (`FOREIGN KEY`) y prevenir el error `Msg 2714` al reejecutar el script[cite: 3].
- **`Dim_Cliente`:** Centraliza a cada usuario una sola vez con su RFC oficial y fecha de alta, resolviendo la duplicación de datos personales por crédito otorgado[cite: 2, 3].
- **`Dim_Producto`:** Normaliza los tipos de préstamo mediante una llave artificial numérica entera (`ID_Producto`), reduciendo cadenas repetitivas y blindando las frecuencias con un constraint `CHECK`[cite: 2, 3].
- **`Dim_Calendario_UMA`:** Parametriza los valores oficiales de la UMA y mantiene una columna calculada físicamente (`PERSISTED`) para consultar al instante el umbral en pesos sin recalcular en cada query[cite: 2, 3].
- **`Fact_Creditos`:** Almacena cada operación crediticia con llaves foráneas a cliente y producto[cite: 1, 2]. Incluye los campos `Registro_Valido` y `Motivo_Inconsistencia` para preservar registros corruptos marcados sin destruirlos de la base[cite: 2, 3].
- **`Fact_Auditoria_LFPIORPI`:** Separada de la operación diaria (relación 1:1) para aislar los cálculos del área de Cumplimiento (acumulado de 180 días, nivel de alerta y bandera obligatoria del SAT)[cite: 2, 3].

---

## SECCIÓN 3: PIPELINE ETL EN PYTHON Y VALIDACIÓN CON IA

### 3.1 Python 
Python procesa el archivo crudo original sin alterar su contenido fuente, normaliza formatos, aplica la ventana móvil retrospectiva y prepara el dataset limpio para insertarse en SQL Server.

### 3.2 Decisiones Técnicas Implementadas
- **Eliminación de redundancias:** Se descartó la columna duplicada `folio 1`[cite: 3].
- **Homogeneización de texto:** Normalización mediante `.str.strip().str.upper()` para garantizar consistencia en nombres y estados[cite: 3].
- **Casting numérico:** Extracción de signos `$` y comas para convertir montos y cuotas a tipo flotante (`float`)[cite: 3].
- **Auditoría sin borrado destructivo:** Los registros incompletos se etiquetan con `Registro_Valido = False` y se especifica la falla en `Motivo_Inconsistencia`, preservando la trazabilidad legal[cite: 3].
- **Mapeo dinámico de UMA:** Cruce anual del valor de UMA por fecha de depósito para calcular el monto exacto en UMAs[cite: 3].
- **Ventana rodante de 180 días:** Algoritmo que ordena cronológicamente por cliente y calcula la acumulación móvil retrospectiva de 180 días naturales[cite: 3].
- **Semáforo optimizado con IA:** Para evitar bucles iterativos lentos (`if/else`), se validó con Inteligencia Artificial el uso de vectorización mediante `np.select`, permitiendo evaluar miles de transacciones de forma simultánea en milisegundos[cite: 3].

- import pandas as pd
import numpy as np

# 1. Carga de archivo
df = pd.read_csv('Basededatos.csv')

# 2. Eliminación de columna duplicada
if 'folio 1' in df.columns:
    df = df.drop(columns=['folio 1'])

# 3. Homogeneización de texto
text_cols = ['folio', 'Empresa', 'RFC', 'Cliente', 'Status', 'Estatus_Cobranza', 'loan_name', 'Frecuencia']
for col in text_cols:
    if col in df.columns:
        df[col] = df[col].astype(str).str.strip().str.upper()
        df[col] = df[col].replace({'NAN': np.nan, 'NONE': np.nan, '': np.nan})

# 4. Limpieza numérica de montos
def limpiar_numero(val):
    if pd.isna(val):
        return np.nan
    if isinstance(val, (int, float)):
        return float(val)
    val_str = str(val).replace('$', '').replace(',', '').replace(' ', '').strip()
    try:
        return float(val_str)
    except ValueError:
        return np.nan

num_cols = ['Monto', 'Cuota', 'Plazo', 'Cuotas', 'Tasa_con_impuesto', 'Tasa_sin_impuesto']
for col in num_cols:
    if col in df.columns:
        df[col] = df[col].apply(limpiar_numero)

# 5. Formato de fechas
date_cols = ['Fecha_Deposito', 'Solicitud', 'Fecha_de_primer_pago']
for col in date_cols:
    if col in df.columns:
        df[col] = pd.to_datetime(df[col], format='mixed', errors='coerce')

# 6. Auditoría sin borrado
df['Registro_Valido'] = True
df['Motivo_Inconsistencia'] = ""

falta_fecha = df['Fecha_Deposito'].isna()
falta_monto = df['Monto'].isna() | (df['Monto'] <= 0)
falta_id = df['RFC'].isna() & df['Cliente'].isna()

df.loc[falta_fecha | falta_monto | falta_id, 'Registro_Valido'] = False
df.loc[falta_fecha, 'Motivo_Inconsistencia'] += "Sin Fecha Deposito; "
df.loc[falta_monto, 'Motivo_Inconsistencia'] += "Sin Monto Valido; "
df.loc[falta_id, 'Motivo_Inconsistencia'] += "Sin Identificador Cliente/RFC; "

# 7. Reglas de UMA y acumulación móvil
uma_dict = {2021: 89.62, 2022: 96.22, 2023: 103.74, 2024: 108.57, 2025: 113.14, 2026: 117.31}
UMBRAL_AVISO_UMAS = 1605.0

df['Anio_Operacion'] = df['Fecha_Deposito'].dt.year
df['Mes_Operacion'] = df['Fecha_Deposito'].dt.to_period('M').astype(str)
df['UMA_Diaria'] = df['Anio_Operacion'].map(uma_dict).fillna(117.31)
df['Monto_UMAs'] = df['Monto'] / df['UMA_Diaria']
df['Acumulado_6M_Pesos'] = 0.0
df['Acumulado_6M_UMAs'] = 0.0
df['Porcentaje_Umbral_Aviso'] = 0.0

id_col = 'RFC' if df['RFC'].notna().any() else 'Cliente'
df_validos = df[df['Registro_Valido']].sort_values(by=[id_col, 'Fecha_Deposito']).copy()

acum_pesos, acum_umas = [], []
for _, row in df_validos.iterrows():
    cliente = row[id_col]
    fecha = row['Fecha_Deposito']
    ventana = df_validos[
        (df_validos[id_col] == cliente) &
        (df_validos['Fecha_Deposito'] <= fecha) &
        (df_validos['Fecha_Deposito'] >= fecha - pd.Timedelta(days=180))
    ]
    acum_pesos.append(ventana['Monto'].sum())
    acum_umas.append(ventana['Monto_UMAs'].sum())

df_validos['Acumulado_6M_Pesos'] = acum_pesos
df_validos['Acumulado_6M_UMAs'] = acum_umas
df_validos['Porcentaje_Umbral_Aviso'] = (df_validos['Acumulado_6M_UMAs'] / UMBRAL_AVISO_UMAS) * 100

df.loc[df_validos.index, 'Acumulado_6M_Pesos'] = df_validos['Acumulado_6M_Pesos']
df.loc[df_validos.index, 'Acumulado_6M_UMAs'] = df_validos['Acumulado_6M_UMAs']
df.loc[df_validos.index, 'Porcentaje_Umbral_Aviso'] = df_validos['Porcentaje_Umbral_Aviso']

# 8. Semáforo vectorial optimizado con IA (np.select)
condiciones = [
    (~df['Registro_Valido'].astype(bool)).values,
    (df['Acumulado_6M_UMAs'].astype(float) >= UMBRAL_AVISO_UMAS).values,
    (df['Acumulado_6M_UMAs'].astype(float) >= (UMBRAL_AVISO_UMAS * 0.80)).values,
    (df['Acumulado_6M_UMAs'].astype(float) >= (UMBRAL_AVISO_UMAS * 0.50)).values
]
etiquetas = [
    'GRIS - REVISIÓN AUDITORÍA / INCONSISTENTE',
    'ROJO - REQUIERE AVISO SAT (>= 1,605 UMAs)',
    'NARANJA - CRÍTICO (>= 80% Umbral)',
    'AMARILLO - PREVENTIVO (>= 50% Umbral)'
]
df['Nivel_Alerta'] = np.select(condiciones, etiquetas, default='VERDE - NORMAL (< 50% Umbral)')
df['Requiere_Aviso_SAT'] = df['Acumulado_6M_UMAs'] >= UMBRAL_AVISO_UMAS

# 9. Guardar archivo final
df.to_csv('Base_Operaciones_Credito_TEC_Limpia.csv', index=False, encoding='utf-8-sig')
print("Pipeline finalizado con éxito.")

### 3.4 Resultados Numéricos del Procesamiento
- 🟢 **Verde (< 50% del umbral):** 9,993 operaciones en rango normal[cite: 3].
- 🔴 **Rojo (≥ 1,605 UMAs):** 11 operaciones que obligan a presentar aviso formal ante el SAT[cite: 3].
- 🟠 **Naranja (80% a 99.9%):** 3 operaciones en nivel crítico cercano al tope[cite: 3].
- 🟡 **Amarillo (50% a 79.9%):** 2 operaciones en seguimiento preventivo[cite: 3].
- ⚪ **Gris (Auditoría):** 2 registros nulos aislados con etiqueta de inconsistencia técnica[cite: 3].

---

## SECCIÓN 4: HOJA DE RUTA EN SEGURIDAD, CONECTIVIDAD SQL Y GOBERNANZA DE DATOS

Como parte de la visión integral del proyecto y su futura transición hacia un entorno productivo formal dentro de FEMSA Digital, se definieron los siguientes requerimientos de seguridad, conectividad y gobernanza de datos. Dado que la configuración avanzada de servidores, arquitecturas seguras y encriptación no forman parte del contenido habitual visto en clase, **nos apoyaremos en herramientas de Inteligencia Artificial como asistente técnico y de investigación** para guiar el diseño y la implementación de estas mejores prácticas:

- **Conectividad Segura y Cifrado en Tránsito (En Desarrollo con Apoyo de IA):**  
  Buscamos establecer el enlace directo entre el script de Python y SQL Server mediante librerías como `SQLAlchemy` y `ODBC Driver 18 for SQL Server`[cite: 3]. Con la guía de IA, estructuraremos cadenas de conexión que fuercen parámetros de cifrado en tránsito (`Encrypt=yes; TrustServerCertificate=no;`) para proteger las credenciales y asegurar que los datos viajen protegidos contra intercepciones en la red corporativa[cite: 3].

- **Control de Acceso Basado en Roles / RBAC (Fase Propuesta con Soporte de IA):**  
  Con el objetivo de restringir la visibilidad de información confidencial de prevención de lavado de dinero, utilizaremos IA para ayudarnos a formular los scripts de permisos y roles en el motor de base de datos[cite: 3]:
  * **Mesa de Crédito / Operaciones:** Tendrá permisos limitados exclusivamente a la lectura de datos comerciales en `Fact_Creditos`[cite: 3].
  * **Oficial de Cumplimiento / AML:** Contará con acceso exclusivo a la tabla `Fact_Auditoria_LFPIORPI` para gestionar las alertas regulatorias y preparar los avisos obligatorios ante el SAT[cite: 3].
  * **Analistas de BI:** Acceso controlado a vistas analíticas agregadas sin exposición de folios auditados en crudo[cite: 3].

- **Privacidad y Cumplimiento LFPDPPP (Propuesta de Anonimización asistida por IA):**  
  Para alinearnos a la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP), el objetivo es construir, con apoyo de IA, una función de anonimización criptográfica[cite: 3]. La intención es reemplazar identificadores directos (como `RFC` y `Nombre_Cliente`) por resúmenes criptográficos irreversibles (`SHA-256` con salt) al generar ambientes de prueba o analíticos, protegiendo la identidad real de los titulares de las cuentas[cite: 3].
