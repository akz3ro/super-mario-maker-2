# Maker Packs

A small tool that installs **Super Mario Maker 2** level packs into your **suyu** save data.
Pick a level folder from a list and the tool copies its contents into the save folder.

> Created by akz3ro

---

## Folder layout

```
Compressed
├── Maker Packs.bat        <- the tool (single file, double-click to run)
├── README.md              <- this file
├── levels                 <- level folders (Week 1 - 1 Easy, Week 2, ...)
└── backups                <- created automatically when you choose to back up
```

Every folder inside `levels` must contain level files (`course_data_1xx.bcd` and `course_thumb_1xx.btl`).

---

## How to run

Double-click `Maker Packs.bat`, or run it from Windows Terminal:

```powershell
cd "C:\Users\AK-Ze\Downloads\Compressed"
.\"Maker Packs.bat"
```

---

## What the tool asks (in order)

1. **Levels path**: press `Enter` to use the `levels` folder next to the tool.
2. **Save game path**: press `Enter` to use the default. It is built from `%APPDATA%`, so it works for any Windows user:
   `...\AppData\Roaming\suyu\nand\user\save\0000000000000000\7D25BAE9D30B00C638F5BA0B4299DE43\01009B90006DC000`
3. **Back up the save folder? (Y/n)**
   - **Y** (or `Enter`): asks where to store the backup. Default is the `backups` folder next to the tool. Each backup goes into its own folder named by date and time, for example `backups\2026-11-04_16-45-30`.
   - **n**: shows a warning that matching save files will be overwritten and lost. Press `Enter` to continue, or type anything and press `Enter` to cancel.
4. **Pick a level folder**:
   - **Up / Down** arrows to move (also PageUp / PageDown / Home / End).
   - Type part of a name to filter, for example `100` or `expert`.
   - **Enter** to select, **Esc** to cancel.

After you select a folder, the tool starts right away with no extra confirmation.

---

## What the tool does

- If suyu is running, it closes it (a normal close first, then a forced close). Unsaved in-game progress will be lost.
- If you chose a backup, it copies the whole save folder first.
- It copies **everything** inside the selected folder into the save folder. Duplicate files are overwritten by the files from the level folder.
- It ends by printing `Created by akz3ro`.

---

## Important notes

- **`.dat` files are replaced.** Each level folder has its own `save.dat`, `network.dat`, `quest.dat` and `later.dat`, and they overwrite yours. Keep the backup option on.
- **The game holds only 60 downloaded levels** (slots 120 to 179), and every pack uses the same slots. You can install one pack at a time, not all of them together.
- **To restore your old save:** close suyu, then copy the contents of your backup folder into the save folder and choose to replace the files.
- If you get a "path not found" error, make sure the game has been launched at least once in suyu and that the save path is correct.

---

# Open Course World (OCW) setup for suyu

[Open Course World](https://opencourse.world/) is a community server for Mario Maker 2 Course World.
These steps are the official Switch (Atmosphere) instructions, adapted for suyu. On suyu the "SD card" is the **`sdmc`** folder.

## Requirements

- Mario Maker 2 at **version 3.0.2 or 3.0.3**. The version number shows in the bottom right when the game starts. If you see no version number, you are on 1.0.0.
- `ocw-mod-v0.3.zip` (the OCW mod package) and your `ocw-config.json`, both downloaded from [opencourse.world](https://opencourse.world/).

## Find the sdmc folder

The default location is:

```
C:\Users\<your user>\AppData\Roaming\suyu\sdmc
```

You can also open it from suyu: **File > Open suyu Folder**, then open `sdmc`.

## Steps

1. **Install the mod.** Unzip `ocw-mod-v0.3.zip` into the `sdmc` folder, at the same level as the `atmosphere` folder. Choose **Replace** if Windows asks. The package puts its files inside `atmosphere/`, so make sure you did not create an extra folder at the root. You can reinstall it any time to get new mod features.
2. **Add your config.** Download your config file from the OCW site and move `ocw-config.json` into the `sdmc` folder, at the same level as the `atmosphere` folder.
3. **Check the result.** Inside `sdmc` you should now see:

   ```
   sdmc
   ├── atmosphere
   └── ocw-config.json
   ```

4. **Start the game.** Open Mario Maker 2 and go to **Course World**. Welcome to OCW!
5. **Manage your account (optional).** Go to [Your Account](https://opencourse.world/account) to manage your courses and import courses you created.

## Important

- `ocw-config.json` identifies you to OCW. **Do not share it with anyone.**
- Downloading a new config **invalidates every token you downloaded before**. Download it only once if you want to use it on several devices.
