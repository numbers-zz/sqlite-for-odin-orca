call odin build . --target=orca_wasm32 -out:module.wasm
call orca bundle --name output --resource-dir data module.wasm
call .\output\bin\output.exe 