---
name: red-erp-environment
description: Connect safely to Red ERP databases and remote/UAT machines by loading the user's private environment.md first. Use for MySQL queries, database troubleshooting, redTools/gen-server checks, UNC/SMB access, WildFly target inspection, deployment-path checks, server logs, or requests mentioning DB, database, remote, UAT, 137, 233, 238, REDDS, standalone.xml, or redTools.
---

# Red ERP Environment

Use this skill whenever work needs a Red ERP database, remote machine, deployed WildFly files, or server logs. Never guess a host, database, username, password, or target path.

## Load the private configuration

Before any connection or connection advice, locate and read the first existing file:

1. `%USERPROFILE%\.red-erp\environment.md` — preferred shared location.
2. `<current-project>\environment.md` — project-local fallback.
3. `C:\Users\Dev\Documents\excelgen\environment.md` — compatibility fallback on the current workstation.

Treat the selected file as secret. Do not paste credentials into chat, commit them, include them in a skill, or expose them in terminal output. If no private file exists, read [environment.example.md](references/environment.example.md), then ask the user to create the private file. Do not infer missing values.

## Choose the target

Confirm the intended purpose before connecting:

- Excel generation/redTools work uses the gen-server endpoint and its database from `environment.md`.
- UAT application behavior uses the datasource actually configured on the target WildFly server. Read `standalone.xml` and resolve the JNDI datasource (commonly `java:/REDDS`) before choosing a database.
- Remote file or log inspection uses the target UNC/SMB path from `environment.md`.
- A dev checkout is not evidence of what is deployed. Compare the actual target file and `LastWriteTime` before diagnosing runtime behavior.

Never assume that the gen database and the application database are the same.

## Safe connection workflow

1. Read the private environment file.
2. Identify the exact environment, host, port, database/schema, and purpose.
3. Test reachability without mutation:
   - Database: connect and run `SELECT DATABASE(), NOW();` or `SELECT 1;`.
   - UNC/SMB: run `Test-Path -LiteralPath '<target>'`, then inspect only the required file.
   - HTTP: request the configured health/tool URL without submitting a generation or mutation action.
4. Report which target was reached without revealing credentials.
5. Perform only the authorized operation.
6. Verify against the same target environment, not a local copy.

## Database rules

- `SELECT`, schema inspection, and connection tests are read-only and allowed when relevant.
- `INSERT`, `UPDATE`, `DELETE`, `REPLACE`, DDL, procedures that mutate data, imports, and restores require explicit user authorization for the exact target and scope.
- Before an authorized mutation, run a narrowing `SELECT` and show the expected row count.
- Prefer a transaction when supported. Preserve the original values needed for rollback.
- Never place passwords directly in reusable scripts, shell history, screenshots, or output. Use an interactive prompt, protected client config, or process-scoped environment variable.
- If the configured connector/client is incompatible with an older server, use the connector version stated in `environment.md`; do not silently switch servers.

## Remote and WildFly rules

- Read-only inspection of deployed files and logs is allowed.
- Writing, replacing, deploying, moving, or deleting remote files requires explicit authorization and an exact target path.
- Before an authorized replacement, compare source and target timestamps/hashes and create a recoverable backup next to the exact target when practical.
- Do not start or restart WildFly or another long-running server. Give the user the exact command or console action to run.
- After the user restarts or reloads, verify using the real target log and deployed file timestamps.

## Sharing with another person

Distribute this skill folder without secrets. Give the recipient [environment.example.md](references/environment.example.md) and have them create:

`%USERPROFILE%\.red-erp\environment.md`

Each person maintains their own private credentials. Add that path to their global Git ignore or ensure it is outside every repository.

## Response checklist

Before claiming a connection or fix is verified:

- State the actual host/environment checked.
- Confirm the configured database or deployed path came from the private environment file or target datasource.
- Confirm verification happened on the target system.
- State any step the user must still perform, especially restart/reload.
