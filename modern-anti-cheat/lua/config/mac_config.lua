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
