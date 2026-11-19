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

# 3. (Opcional) Ver el log de la carga inicial; debe terminar sin errores
docker compose -f imagen_postgre.yaml logs postgres

# 4. Consultar los datos cargados
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -c "SET search_path TO hr, public; SELECT * FROM employees LIMIT 10;"

# 5. Abrir una consola SQL dentro de PostgreSQL
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda
```

Dentro de `psql`:

```sql
SET search_path TO hr, public;
\dt
SELECT * FROM emp_details_view LIMIT 10;
```

> El esquema se llama `hr`, así que en cada sesión nueva hay que ejecutar `SET search_path TO hr, public;` o escribir los nombres completos (por ejemplo `hr.employees`).

## Reinicio limpio

Los scripts de `init/` solo se ejecutan la primera vez que se crea el volumen. Para reconstruir la base de datos desde cero:

```bash
# 1. Detener los contenedores y eliminar el volumen con todos los datos anteriores
docker compose -f imagen_postgre.yaml down -v

# 2. Crear nuevamente el modelo e insertar los datos
docker compose -f imagen_postgre.yaml up -d
```

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

Para registrar el servidor en pgAdmin (Register > Server), usa como **Host** `postgres` (el nombre del servicio dentro de la red de Docker) y **no** `localhost`, porque pgAdmin corre en otro contenedor. Puerto `5432`, usuario `admin`, contraseña `admin123`, base de datos `tienda`. Las tablas aparecen en *Schemas > hr > Tables*.

## Carga manual

Los scripts **no son re-ejecutables** sobre una base que ya tiene los datos (fallarían por tablas existentes y claves duplicadas). Si necesitas recargarlos sin recrear el volumen, borra primero el esquema:

```bash
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -c "DROP SCHEMA IF EXISTS hr CASCADE;"
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -v ON_ERROR_STOP=1 -f /docker-entrypoint-initdb.d/hr_create.sql
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -v ON_ERROR_STOP=1 -f /docker-entrypoint-initdb.d/hr_populate.sql
```

## Solución de problemas

- **No aparecen las tablas:** revisa `docker compose -f imagen_postgre.yaml logs postgres`. Si el volumen ya existía de una ejecución anterior con scripts defectuosos, los scripts no se vuelven a ejecutar: haz el *Reinicio limpio* (`down -v`).
- **Error `invalid input syntax for type date`:** indica que se está usando una versión antigua de `hr_populate.sql` con fechas como `DATE '$3-$2-$1'`. Usa la versión corregida de este repositorio.