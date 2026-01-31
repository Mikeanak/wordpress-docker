# Scripts

- `entrypoint.sh` – container entrypoint; parses env.yaml, handles --restore / --skip-db, seeds or restores DB, starts Apache.
- `seed_photo.sh` – imports john-doe.png and creates a landing page.
- `restore_db.sh` – restores database from a tar.gz containing dump.sql.
