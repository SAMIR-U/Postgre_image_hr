# Modelo HR en PostgreSQL con Docker

Este proyecto inicia PostgreSQL 17 y pgAdmin, y carga automáticamente el esquema `hr` (modelo de ejemplo de Oracle) con sus datos.

Al terminar la carga tendrás: 5 regiones, 25 países, 23 ubicaciones, 27 departamentos, 19 cargos, 107 empleados y 10 registros en el historial de cargos.

## Requisitos

- Docker Desktop (incluye Docker Compose)

## Estructura

```
.
├── imagen_postgre.yaml
├── readme.md
└── init/
    ├── hr_create.sql     # crea el esquema hr, tablas, vista, índices y comentarios
    └── hr_populate.sql   # inserta los datos y crea la FK circular dept_mgr_fk
```

Los scripts de `init/` se ejecutan en orden alfabético (primero `hr_create.sql`, luego `hr_populate.sql`).

## Comandos en orden

Desde la carpeta del proyecto:

```bash
# 1. Crear e iniciar PostgreSQL y pgAdmin
docker compose -f imagen_postgre.yaml up -d

# 2. Verificar que los contenedores estén activos
docker compose -f imagen_postgre.yaml ps

# 3. Esperar a que termine la carga inicial (ver la nota de abajo)
docker compose -f imagen_postgre.yaml logs postgres

# 4. Comprobar que los datos se cargaron (debe devolver 107)
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -c "SET search_path TO hr, public; SELECT count(*) FROM employees;"

# 5. Consultar algunos empleados
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -c "SET search_path TO hr, public; SELECT * FROM employees LIMIT 10;"

# 6. Abrir una consola SQL dentro de PostgreSQL
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda
```

> **Importante: revisa el log antes de consultar (paso 3).** La carga inicial solo ocurre cuando el volumen de datos se crea desde cero, y tarda unos segundos. Debes ver, en este orden, `PostgreSQL init process complete; ready for start up.` y `database system is ready to accept connections`.
>
> Si en cambio ves `Database directory appears to contain a database; Skipping initialization`, el volumen ya existía de una ejecución anterior y **los scripts de `init/` no se ejecutaron**: las tablas pueden estar vacías o incompletas. En ese caso haz el *Reinicio limpio* (`down -v`).
>
> El nombre del servicio es `postgres` (no `postgre`); si lo escribes mal, Compose responde `no such service`.

### Dentro de `psql`

Ejecuta los comandos **de uno en uno**, no pegados todos juntos. Los comandos con barra invertida (`\dt`) toman el resto de la línea como argumentos, y si pegas varias líneas a la vez, `psql` puede interpretar la siguiente sentencia como parte de ese comando.

```sql
SET search_path TO hr, public;
```
```sql
\dt
```
```sql
SELECT * FROM emp_details_view LIMIT 10;
```

Si el prompt cambia a `tienda-#`, significa que `psql` espera que termines una sentencia con `;`. Presiona `Ctrl+C` para cancelarla. Para salir, escribe `\q`.

> El esquema se llama `hr`, así que en cada sesión nueva hay que ejecutar `SET search_path TO hr, public;` o escribir los nombres completos (por ejemplo `hr.employees`).

## Reinicio limpio

Los scripts de `init/` solo se ejecutan la primera vez que se crea el volumen. Para reconstruir la base de datos desde cero:

```bash
# 1. Detener los contenedores y eliminar el volumen con todos los datos anteriores
docker compose -f imagen_postgre.yaml down -v

# 2. Crear nuevamente el modelo e insertar los datos
docker compose -f imagen_postgre.yaml up -d
```

Después revisa el log (`logs postgres`) y confirma que aparece `PostgreSQL init process complete` antes de consultar.

## Accesos

PostgreSQL:

- Host: `localhost`
- Puerto: `5432`
- Base de datos: `tienda`
- Usuario: `admin`
- Contraseña: `admin123`

pgAdmin:

- URL: http://localhost:5050
- Email: `admin@demo.com`
- Contraseña: `admin123`

Para registrar el servidor en pgAdmin (object > Register > Server), usa como **Host** `postgres` (el nombre del servicio dentro de la red de Docker) y **no** `localhost`, porque pgAdmin corre en otro contenedor. Puerto `5432`, usuario `admin`, contraseña `admin123`, base de datos `tienda`. Las tablas aparecen en *Schemas > hr > Tables*.

## Carga manual

Los scripts **no son re-ejecutables** sobre una base que ya tiene los datos (fallarían por tablas existentes y claves duplicadas). Si necesitas recargarlos sin recrear el volumen, borra primero el esquema:

```bash
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -c "DROP SCHEMA IF EXISTS hr CASCADE;"
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -v ON_ERROR_STOP=1 -f /docker-entrypoint-initdb.d/hr_create.sql
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -v ON_ERROR_STOP=1 -f /docker-entrypoint-initdb.d/hr_populate.sql
```

## Solución de problemas

- **Las tablas existen pero `employees` tiene 0 filas:** casi siempre el log muestra `Skipping initialization`, es decir, se reutilizó un volumen creado por una ejecución anterior (por ejemplo, con scripts defectuosos). Haz el *Reinicio limpio* (`down -v`). Con `down` sin `-v` los datos del volumen se conservan.
- **No aparecen las tablas:** revisa `docker compose -f imagen_postgre.yaml logs postgres`. Si el volumen ya existía de una ejecución anterior con scripts defectuosos, los scripts no se vuelven a ejecutar: haz el *Reinicio limpio* (`down -v`).
- **Error `invalid input syntax for type date`:** indica que se está usando una versión antigua de `hr_populate.sql` con fechas como `DATE '$3-$2-$1'`. Usa la versión corregida y haz el *Reinicio limpio*.
- **VS Code marca error en `CREATE SCHEMA IF NOT EXISTS`:** es un falso positivo si el archivo está en modo Oracle SQL. La sintaxis es válida en PostgreSQL; cambia el lenguaje del archivo a PostgreSQL o SQL.