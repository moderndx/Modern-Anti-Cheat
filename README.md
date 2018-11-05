![Foo](https://i.imgur.com/VQL6rfG.png)

![Foo](https://i.imgur.com/Af8rZSA.png)

Modern Anti Cheat was made with the understanding that larger and more popular servers cant support resource heavy anti cheats and so they're left with inferior anti cheats or even no anti cheat. Modern Anti Cheat is extremely optimized for larger servers and wont slow down your server. ModernAC isn't going to clutter your server with useless UIs and notifications, we keep it simple but allow you to delve deeper into logging with the Discord logging support.



![Foo](https://i.imgur.com/Lhy6enx.png)

* Easy to setup, just drag and drop
* Configuration is easy
* Near-instant detection on most lua cheats
* Informative console &amp; file logging, you'll know what someone was banned for exactly
* Supports ULX, Serverguard, and Maestro
* Update checks notify you of an available update
* Discord logging
* No DRM


![Foo](https://i.imgur.com/qhZW3pb.png)

Although there shouldn't be any issues here are some basic fixes

* Players are being falsely banned for x reason
* Disable the detection method in the config file


* The steam family share check isn't working
* Grab a new key from here


* The discord logging isn't working
* Re-read and follow all the instructions in the config file


* The anti cheat isn't working or loading
* Make sure you placed it in your server addon folder, contact me if something isn't working


If any issues arise that you can't fix don't hesitate to open a support ticket.



![Foo](https://i.imgur.com/6caEqAw.png)

* ULX
     * Bans
     * Ban-evasion checks
* Maestro
     * Bans
     * Ban-evasion checks
* ServerGuard
     * Bans
* Other
     * Discord logging



![Foo](https://i.imgur.com/Ubslg1X.png)

![Foo](https://i.imgur.com/OPs7nMF.png)



![Foo](https://i.imgur.com/PMPyvVj.png)

Configurations are done in mac_config.lua

```lua
modern_anti_cheat_config = {}
// == CONFIG

--[[
HOW TO GET WEBHOOK
1. Open your Server Settings Webhook tab by right clicking the settings icon on a channel and clicking Webhooks
2. Click the blue-purple button that says "Create Webhook"
   You'll have a few options here. You can:
    Edit the avatar: By clicking the avatar next to the Name in the top left
    Choose what channel the Webhook posts to: By selecting the desired text channel in the  dropdown menu.
    Name your Webhook: Good for distinguishing multiple webhooks for multiple different services.

You can now paste the URL in the discord_webhook config area below
]]--

modern_anti_cheat_config.discord_webhook = "" -- Read above

modern_anti_cheat_config.m_log_discord = true -- Relays data to a discord webhook (set above)

--[[
HOW TO GET A STEAM API KEY

1. Visit https://steamcommunity.com/dev/apikey
2. Name the key something
3. Create the key

You can now paste the key in the steam_api_key area below
]]--

modern_anti_cheat_config.steam_api_key = "" -- Read above

modern_anti_cheat_config.kick_banned_family_shared = true -- Kicks players if they are using a family shared account where the sharer has been previously banned
modern_anti_cheat_config.kick_all_family_shared = false -- Kicks players if they are using a family shared account

// == INGAME LOGGING CONFIG
modern_anti_cheat_config.m_log_console = true -- Logs data to the console
modern_anti_cheat_config.m_log_file = true -- Logs data to /data/modernac_log.txt

// == BAN REASON
modern_anti_cheat_config.m_use_custom_ban_reason = true -- Bans players with the below reason
modern_anti_cheat_config.m_ban_reason = "[MAC] Invalid lua executed"

// == DETECTION CONFIG
modern_anti_cheat_config.m_validate_players = true -- Validates players, kicks them if it fails
modern_anti_cheat_config.m_check_file = true -- Validates files that call certain functions
modern_anti_cheat_config.m_check_function = true -- Validates functions that call certain functions
modern_anti_cheat_config.m_check_globals = true -- Checks for global variables related to cheating
modern_anti_cheat_config.m_check_modules = true -- Checks for loading modules used for cheating
modern_anti_cheat_config.m_check_cvars = true -- Checks for cheating related cvars
modern_anti_cheat_config.m_check_synced_cvars = true -- Validates convars are synced with the server
modern_anti_cheat_config.m_check_external = true -- Checks if lua was loaded with the external2 bypass
modern_anti_cheat_config.m_check_dhtml = true -- Validates code ran through DHTML, which is used as a cac bypass
modern_anti_cheat_config.m_check_cleaning_screen = true -- Checks if a player is sending back false screen captures
modern_anti_cheat_config.m_check_detoured_functions = true -- Checks if a player is overwriting important functions
modern_anti_cheat_config.m_simulate_backdoors = true -- Simulates backdoor netmessages to ban players
modern_anti_cheat_config.m_backup_kick_check = true -- Uses a backup method of checking if a player should be banned

```

![Foo](https://i.imgur.com/XF3UN7h.png)

modern_verified_player(ply) -- Called when a player is verified

modern_banned_player(ply, reason) -- Called when a player is being banned

modern_kicked_player(ply, reason, silent) -- Called when a player is being kicked

