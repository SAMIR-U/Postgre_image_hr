-- PostgreSQL HR sample schema
-- Equivalent of the Oracle HR model

CREATE SCHEMA IF NOT EXISTS hr;
SET search_path TO hr, public;

CREATE TABLE regions (
    region_id integer CONSTRAINT region_id_nn NOT NULL,
    region_name varchar(25),
    CONSTRAINT reg_id_pk PRIMARY KEY (region_id)
);

CREATE TABLE countries (
    country_id char(2) CONSTRAINT country_id_nn NOT NULL,
    country_name varchar(60),
    region_id integer,
    CONSTRAINT country_c_id_pk PRIMARY KEY (country_id),
    CONSTRAINT countr_reg_fk FOREIGN KEY (region_id)
        REFERENCES regions(region_id)
);

CREATE TABLE locations (
    location_id integer,
    street_address varchar(40),
    postal_code varchar(12),
    city varchar(30) CONSTRAINT loc_city_nn NOT NULL,
    state_province varchar(25),
    country_id char(2),
    CONSTRAINT loc_id_pk PRIMARY KEY (location_id),
    CONSTRAINT loc_c_id_fk FOREIGN KEY (country_id)
        REFERENCES countries(country_id)
);

CREATE SEQUENCE locations_seq
    START WITH 3300
    INCREMENT BY 100
    MAXVALUE 9900
    NO CYCLE;

CREATE TABLE departments (
    department_id integer,
    department_name varchar(30) CONSTRAINT dept_name_nn NOT NULL,
    manager_id integer,
    location_id integer,
    CONSTRAINT dept_id_pk PRIMARY KEY (department_id),
    CONSTRAINT dept_loc_fk FOREIGN KEY (location_id)
        REFERENCES locations(location_id)
);

CREATE SEQUENCE departments_seq
    START WITH 280
    INCREMENT BY 10
    MAXVALUE 9990
    NO CYCLE;

CREATE TABLE jobs (
    job_id varchar(10),
    job_title varchar(35) CONSTRAINT job_title_nn NOT NULL,
    min_salary numeric(6),
    max_salary numeric(6),
    CONSTRAINT job_id_pk PRIMARY KEY (job_id)
);

CREATE TABLE employees (
    employee_id integer,
    first_name varchar(20),
    last_name varchar(25) CONSTRAINT emp_last_name_nn NOT NULL,
    email varchar(25) CONSTRAINT emp_email_nn NOT NULL,
    phone_number varchar(20),
    hire_date date CONSTRAINT emp_hire_date_nn NOT NULL,
    job_id varchar(10) CONSTRAINT emp_job_nn NOT NULL,
    salary numeric(8,2),
    commission_pct numeric(2,2),
    manager_id integer,
    department_id integer,
    CONSTRAINT emp_salary_min CHECK (salary > 0),
    CONSTRAINT emp_email_uk UNIQUE (email),
    CONSTRAINT emp_emp_id_pk PRIMARY KEY (employee_id),
    CONSTRAINT emp_dept_fk FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT emp_job_fk FOREIGN KEY (job_id) REFERENCES jobs(job_id),
    CONSTRAINT emp_manager_fk FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

CREATE SEQUENCE employees_seq
    START WITH 207
    INCREMENT BY 1
    NO CYCLE;

CREATE TABLE job_history (
    employee_id integer CONSTRAINT jhist_employee_nn NOT NULL,
    start_date date CONSTRAINT jhist_start_date_nn NOT NULL,
    end_date date CONSTRAINT jhist_end_date_nn NOT NULL,
    job_id varchar(10) CONSTRAINT jhist_job_nn NOT NULL,
    department_id integer,
    CONSTRAINT jhist_date_interval CHECK (end_date > start_date),
    CONSTRAINT jhist_emp_id_st_date_pk PRIMARY KEY (employee_id, start_date),
    CONSTRAINT jhist_job_fk FOREIGN KEY (job_id) REFERENCES jobs(job_id),
    CONSTRAINT jhist_emp_fk FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT jhist_dept_fk FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE VIEW emp_details_view AS
SELECT
    e.employee_id,
    e.job_id,
    e.manager_id,
    e.department_id,
    d.location_id,
    l.country_id,
    e.first_name,
    e.last_name,
    e.salary,
    e.commission_pct,
    d.department_name,
    j.job_title,
    l.city,
    l.state_province,
    c.country_name,
    r.region_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN jobs j ON j.job_id = e.job_id
JOIN locations l ON d.location_id = l.location_id
JOIN countries c ON l.country_id = c.country_id
JOIN regions r ON c.region_id = r.region_id;

CREATE INDEX emp_department_ix ON employees(department_id);
CREATE INDEX emp_job_ix ON employees(job_id);
CREATE INDEX emp_manager_ix ON employees(manager_id);
CREATE INDEX emp_name_ix ON employees(last_name, first_name);
CREATE INDEX dept_location_ix ON departments(location_id);
CREATE INDEX jhist_job_ix ON job_history(job_id);
CREATE INDEX jhist_employee_ix ON job_history(employee_id);
CREATE INDEX jhist_department_ix ON job_history(department_id);
CREATE INDEX loc_city_ix ON locations(city);
CREATE INDEX loc_state_province_ix ON locations(state_province);
CREATE INDEX loc_country_ix ON locations(country_id);

COMMENT ON TABLE regions IS 'Regions table that contains region numbers and names.';
COMMENT ON COLUMN regions.region_id IS 'Primary key of regions table.';
COMMENT ON COLUMN regions.region_name IS 'Region name.';
COMMENT ON TABLE countries IS 'Countries table.';
COMMENT ON COLUMN countries.country_id IS 'Primary key of countries table.';
COMMENT ON COLUMN countries.country_name IS 'Country name.';
COMMENT ON COLUMN countries.region_id IS 'Foreign key to regions.region_id.';
COMMENT ON TABLE locations IS 'Office, warehouse or production locations.';
COMMENT ON COLUMN locations.location_id IS 'Primary key of locations table.';
COMMENT ON COLUMN locations.city IS 'City where the location is situated.';
COMMENT ON COLUMN locations.country_id IS 'Foreign key to countries.country_id.';
COMMENT ON TABLE departments IS 'Departments where employees work.';
COMMENT ON COLUMN departments.department_id IS 'Primary key of departments table.';
COMMENT ON COLUMN departments.department_name IS 'Department name.';
COMMENT ON COLUMN departments.manager_id IS 'Foreign key to employees.employee_id.';
COMMENT ON COLUMN departments.location_id IS 'Foreign key to locations.location_id.';
COMMENT ON TABLE jobs IS 'Available job titles and salary ranges.';
COMMENT ON COLUMN jobs.job_id IS 'Primary key of jobs table.';
COMMENT ON COLUMN jobs.job_title IS 'Job title.';
COMMENT ON COLUMN jobs.min_salary IS 'Minimum salary for a job.';
COMMENT ON COLUMN jobs.max_salary IS 'Maximum salary for a job.';
COMMENT ON TABLE employees IS 'Employee personnel information.';
COMMENT ON COLUMN employees.employee_id IS 'Primary key of employees table.';
COMMENT ON COLUMN employees.first_name IS 'First name.';
COMMENT ON COLUMN employees.last_name IS 'Last name.';
COMMENT ON COLUMN employees.email IS 'Unique email address.';
COMMENT ON COLUMN employees.phone_number IS 'Phone number.';
COMMENT ON COLUMN employees.hire_date IS 'Employee hire date.';
COMMENT ON COLUMN employees.job_id IS 'Foreign key to jobs.job_id.';
COMMENT ON COLUMN employees.salary IS 'Monthly salary.';
COMMENT ON COLUMN employees.commission_pct IS 'Commission percentage.';
COMMENT ON COLUMN employees.manager_id IS 'Foreign key to employees.employee_id.';
COMMENT ON COLUMN employees.department_id IS 'Foreign key to departments.department_id.';
COMMENT ON TABLE job_history IS 'Previous jobs held by employees.';
COMMENT ON COLUMN job_history.employee_id IS 'Foreign key to employees.employee_id.';
COMMENT ON COLUMN job_history.start_date IS 'Start date of the job.';
COMMENT ON COLUMN job_history.end_date IS 'End date of the job.';
COMMENT ON COLUMN job_history.job_id IS 'Foreign key to jobs.job_id.';
COMMENT ON COLUMN job_history.department_id IS 'Foreign key to departments.department_id.';
