## 2026-11-19 - The menus' own tune

- The menus play a tune of their own (`audio/music.gd`, style "menu"): a breezy bossa in G, vibes over a whistle, sixteen bars with its own melody and chords, picked from three previews. It plays on the main menu and the screens it opens (the wardrobe, YOUR WALKS, settings, controls, credits), the wardrobe opened from the walk select included.
- The walk select and GET READY play the shown walk's own tune, so browsing walks is hearing them (`main._menu_music`).
- The intro film still drops into the title theme on the bark; as it ends, the menus' tune fades in from the top. The title theme stays after a walk's end-of-walk sting.
- `tests/test_menu_music.gd`, listed in `tests/ci.d/menu-music.txt`.
