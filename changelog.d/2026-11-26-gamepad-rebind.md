## 2026-11-26 - Gamepad play, trigger support, and per-action rebinding

- Removed preset control layouts (`DEFAULT`, `ARROWS`, `COMPACT`, `SOUTHPAW`) from Settings and `CONTROLS`, turning the Settings `CONTROLS` row into a submenu entry showing `DEFAULT` or `CUSTOM` and letting players bind any keyboard key, gamepad button, analog trigger, or movement stick axis per action.
- Moved default gamepad zoomies (`turbo`) to the right trigger (`JOY_AXIS_TRIGGER_RIGHT`), updated `Prompts` to support analog triggers (`RT` / `R2`, `LT` / `L2`), and added automatic Xbox / PlayStation prompt detection (`--prompts=ps` or connected joypad name) with live HUD and menu prompt refreshes when switching devices.
- Updated `rebind_input` and `pad_binds` persistence to accept and save analog trigger and movement stick axis bindings alongside key and button binds.
