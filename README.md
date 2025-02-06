This repository contains a minimal VFS layer for running sqlite on the Orca runtime with Odin.

To compile sqlite for Orca wasm, run sqlite_src/sqlite-amalgamation-3480000/wasm_build.bat

To compile and run the example program, run build.bat.
 - "init test.db" creates database test.db
 - "exec" feeds in the sql command you write next.

 E.g.

 - "init start.db"
 - "exec"
 - "CREATE TABLE IF NOT EXISTS config (version TEXT)"
 - "exec"
 - "REPLACE INTO config VALUES ("0.0.1")"

Adapted from the Odin sqlite bindings by Skytrias