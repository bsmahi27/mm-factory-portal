# MM Factory Portal 
The Mid-Market Factory Portal covering prospects, campaigns,
solutions & assets, triggers radar, Smart Agents, governance, KPIs and
administration.
## Prerequisites 

- Java 25
- Spring Boot 4.x.x
- Spring Modules Covered: Spring Boot Web, Spring Data Postgres, Spring Actuator, OpenAPI, Flyway, Lombok
- Database: PostgreSQL
- IDE: IntelliJ IDEA (recommended)
- Build Tool: Maven

## Option1: PostgreSQL Setup (pgAdmin)

## Step 1: Create Login/User

1. Open **pgAdmin**
2. Navigate to:

```text
Servers
 └── PostgreSQL
      └── Login/Group Roles
```

3. Right-click **Login/Group Roles**
4. Select **Create → Login/Group Role**

### General

```text
Name: mmfactory
```

### Definition

```text
Password: mmfactory
```

### Privileges

Enable:

```text
Can login
```

Click **Save**.

---

## Step 2: Create Database

1. Navigate to:

```text
Servers
 └── PostgreSQL
      └── Databases
```

2. Right-click **Databases**
3. Select **Create → Database**

Enter:

```text
Database Name : mm_factory_portal
Owner         : mmfactory
```

Click **Save**.

---

## Step 3: Configure Schema Permissions

Open:

```text
Databases
 └── mm_factory_portal
      └── Query Tool
```

Run:

```sql
ALTER SCHEMA public OWNER TO mmfactory;

GRANT ALL ON SCHEMA public TO mmfactory;

GRANT USAGE ON SCHEMA public TO mmfactory;

GRANT CREATE ON SCHEMA public TO mmfactory;

GRANT ALL PRIVILEGES
ON DATABASE mm_factory_portal
TO mmfactory;
```

---

## Step 4: Verify Configuration

Run:

```sql
SELECT current_database();

SELECT current_user;
```

Expected:

```text
current_database
----------------
mm_factory_portal
```

---

Verify database owner:

```sql
SELECT datname,
       pg_catalog.pg_get_userbyid(datdba) AS owner
FROM pg_database
WHERE datname='mm_factory_portal';
```

Expected:

```text
datname            | owner
-------------------+----------
mm_factory_portal  | mmfactory
```

---

## Step 5: Validate Permissions

Run:

```sql
CREATE TABLE test_permission (
    id UUID PRIMARY KEY
);

DROP TABLE test_permission;
```

If both statements execute successfully, Flyway migrations will work correctly.

---

# Spring Boot Configuration

Add to `application.properties`:

```properties
spring.application.name=mm-factory-portal

spring.datasource.url=jdbc:postgresql://localhost:5432/mm_factory_portal
spring.datasource.username=mmfactory
spring.datasource.password=mmfactory

spring.jpa.show-sql=true
spring.jpa.hibernate.ddl-auto=validate

spring.flyway.enabled=true
spring.flyway.baseline-on-migrate=true

server.port=8080
```

---

# Run Application

```bash
mvn clean spring-boot:run
```

Verify:

```text
http://localhost:8080/actuator/health
```

Swagger UI:

```text
http://localhost:8080/swagger-ui.html
```

## Option 2: PostgreSQL Setup using CLI

Login as the PostgreSQL superuser:

```bash
psql -U postgres
```

Execute the following script:

```sql
-- Create application user
CREATE USER mmfactory WITH PASSWORD 'mmfactory';

-- Create database
CREATE DATABASE mm_factory_portal OWNER mmfactory;

-- Connect to database
\c mm_factory_portal

-- Set schema ownership
ALTER SCHEMA public OWNER TO mmfactory;

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO mmfactory;
GRANT USAGE ON SCHEMA public TO mmfactory;
GRANT CREATE ON SCHEMA public TO mmfactory;

-- Grant database permissions
GRANT ALL PRIVILEGES
ON DATABASE mm_factory_portal
TO mmfactory;

-- Verify database ownership
SELECT datname, pg_catalog.pg_get_userbyid(datdba) AS owner
FROM pg_database
WHERE datname = 'mm_factory_portal';
```

Expected output:

```text
      datname       |   owner
--------------------+-----------
 mm_factory_portal  | mmfactory
```

# Contributing to MM Factory Portal

## Contribution Guidelines
1. **Fork and clone** the repository:
    ```shell
    git clone https://github.com/<your-username>/mm-factory-portal.git
    cd mm-factory-portal
    ```
2. **Create a branch** off `main`:
    ```shell
    git checkout -b my-feature-branch main
    ```
3. **Implement your changes.** Follow the [code style](#code-style) guidelines, add tests.
4. **Build and test locally:**
    ```shell
    ./mvnw build
    ```
5. **Commit** using [Conventional Commits](#commit-messages) format with a [DCO sign-off](#dco-sign-off):
    ```shell
    git add .
    git commit -s -m "feat(module): Add new feature"
    ```
6. **Keep your branch updated** via rebase (never merge):
    ```shell
    git fetch upstream
    git rebase upstream/main
    ```
7. **Push and open a PR** targeting `main`. Ensure the PR title follows [Conventional Commits](#commit-messages) format and fill out the PR template.
8. **Address review feedback.** Maintainers will review your PR. Push additional signed-off commits as needed.


## Development Guidelines

### Code Style

* The project uses [.editorconfig](/.editorconfig) for formatting. Ensure your editor respects it.
* Use explicit imports (no wildcards).
* Follow existing alphabetical sorting conventions.

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for both commit messages and PR titles.

```
<type>[optional scope]: <description>
```
