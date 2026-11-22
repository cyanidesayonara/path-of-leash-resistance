## 2026-11-22 - Add Store listing languages only once the Store has the package

- `tools/store_listing.py` adds a ca-ES or es-ES Store listing only when a package the Store has already ingested declares that language. The Store refused the v1.76 draft ("Language codes: ca-ES|es-ES not supported") because 1.76 is the first package to declare them; 1.76 goes out with its English listing and the next submission adds the Catalan and Spanish ones.
