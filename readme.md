# Modelo HR en PostgreSQL con Docker

Este proyecto inicia PostgreSQL 17 y carga automáticamente el esquema `hr` y sus datos de ejemplo.

## Requisitos

- Docker Desktop
- Docker Compose

## Comandos en orden

Desde la carpeta del proyecto:

```bash
# 1. Crear e iniciar PostgreSQL y pgAdmin
docker compose -f imagen_postgre.yaml up -d

# 2. Verificar que los contenedores estén activos
docker compose -f imagen_postgre.yaml ps

# 3. Consultar los datos cargados
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -c "SET search_path TO hr, public; SELECT * FROM employees LIMIT 10;"

# 4. Abrir una consola SQL dentro de PostgreSQL
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda
```

Dentro de `psql`:

```sql
SET search_path TO hr, public;
\dt
SELECT * FROM emp_details_view LIMIT 10;
```

## Reinicio limpio

Los scripts de `init/` solo se ejecutan la primera vez que se crea el volumen. Para reconstruir la base de datos con el modelo HR:

```bash
# 1. Detener los contenedores
docker compose -f imagen_postgre.yaml down

# 2. Eliminar el volumen y todos los datos anteriores
docker compose -f imagen_postgre.yaml down -v

# 3. Crear nuevamente el modelo e insertar los datos
docker compose -f imagen_postgre.yaml up -d
```

## Accesos

- pgAdmin: http://localhost:5050
- Email: `admin@demo.com`
- Contraseña: `admin123`
- PostgreSQL: `localhost:5432`
- Base de datos: `tienda`
- Usuario: `admin`
- Contraseña: `admin123`

## Carga manual

Solo si se necesita volver a cargar los scripts sin recrear el volumen:

```bash
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -f /docker-entrypoint-initdb.d/hr_create.sql
docker compose -f imagen_postgre.yaml exec postgres psql -U admin -d tienda -f /docker-entrypoint-initdb.d/hr_populate.sql
```