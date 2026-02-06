PW Pro
=====

Lightweight pressure-washing companion app (SwiftUI).

Getting started
---------------

Requirements
- Xcode 15+ (or matching your toolchain)
- macOS
- iOS Simulator (any recent device)

Build (CLI)

Run the app for the iPhone 17 simulator:

```bash
xcodebuild -project "PW Pro.xcodeproj" -scheme "PW Pro" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' clean build
```

Open and run in Xcode for interactive debugging and simulator management.

Supabase: Seeding the chemicals table
------------------------------------

Two options: Supabase UI or CLI/psql.

1) Using the Supabase SQL editor (UI)
- Create a new project at https://app.supabase.com
- Open the SQL Editor and run the contents of `supabase_schema.sql` to create the `chemicals` table.
- Use the Table Editor Import feature to upload `chemicals.json` and map fields to the table columns.

2) Using Supabase CLI / psql (recommended for automation)
- Install Supabase CLI: https://supabase.com/docs/guides/cli
- Authenticate and link to your project, then run the SQL file:

```bash
supabase db remote set <YOUR_DB_URL>
# or run psql directly against your DB
psql <CONNECTION_STRING> -f supabase_schema.sql
```

- Import `chemicals.json` using a small Node/Python script or `jq` + `psql` loader. Example using `psql` + `COPY` if converted to CSV, or a simple Node script below:

Node import example (quick):

```js
// import-chemicals.js
const fs = require('fs');
const { Client } = require('pg');
const data = JSON.parse(fs.readFileSync('chemicals.json'));
(async () => {
  const c = new Client({ connectionString: process.env.SUPABASE_DB });
  await c.connect();
  for (const item of data) {
    await c.query(
      `INSERT INTO public.chemicals (id, name, short_description, uses, precautions, mixing_note, sds_url)
       VALUES ($1,$2,$3,$4,$5,$6,$7)`,
      [item.id || null, item.name, item.shortDescription, item.uses, item.precautions, item.mixingNote, item.sdsURL]
    );
  }
  await c.end();
  console.log('Imported', data.length);
})();
```

Set `SUPABASE_DB` (Postgres connection string) and run:

```bash
node import-chemicals.js
```

Environment
-----------

Create a `.env` file (not committed) with Supabase credentials. See `.env.example` for keys.

Git
---

Initialize the repo and push to your GitHub remote (replace with your URL):

```bash
git init
git add .
git commit -m "Initial project files and chemical seed"
git branch -M main
git remote add origin https://github.com/furnacerat/PW-Pro.git
git push -u origin main
```

Notes
-----
- The app currently uses a local static chemical dataset (`ChemicalData`). After seeding Supabase you can replace the local store with API calls to fetch chemicals.
- Avoid committing `.env` or secret keys.
