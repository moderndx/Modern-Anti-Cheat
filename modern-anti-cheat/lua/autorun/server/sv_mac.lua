include("config/mac_config.lua")
// == NETWORKING
local m_network_strings = {"m_validate_player", "m_network_data", "m_check_synced_data", "m_loaded", "backup_data_transfer"}

for k, v in pairs( m_network_strings ) do
  util.AddNetworkString( v )
end
// == NETWORKING

// == LOCAL DATA
local anti_cheat_version = "0013"

local bad_net_messages = {"Sandbox_ArmDupe", "Sbox_darkrp", "Sbox_itemstore", "Ulib_Message", "ULogs_Info", "ITEM", "R8", "fix", "Fix_Keypads", "Remove_Exploiters", "noclipcloakaesp_chat_text", "_Defqon", "_CAC_ReadMemory", "nocheat", "LickMeOut", "ULX_QUERY2", "ULXQUERY2", "MoonMan", "Im_SOCool", "Sandbox_GayParty", "DarkRP_UTF8", "oldNetReadData", "memeDoor", "BackDoor", "OdiumBackDoor", "SessionBackdoor", "DarkRP_AdminWeapons", "cucked", "ZimbaBackDoor", "enablevac", "killserver", "fuckserver", "cvaraccess", "DefqonBackdoor"}
// == LOCAL DATA

// == TEMPORARY DATA
local current_server_key = "empty"

local verified_player_data = {}

local player_verification_data = {}
// == TEMPORARY DATA

// == UTIL FUNCS
local function generate_string(string_length)
  local output_str = ""
  for i = 1, string_length do
    output_str = output_str .. string.char(math.random(97, 122))
  end
  return output_str
end

current_server_key = generate_string(10)

local function write_to_file(filename, contents)
	data = file.Read(filename)
	if ( data ) then
		file.Write(filename, data .. "\r\n" .. tostring(contents))
	else
		file.Write(filename, tostring(contents))
	end
end

local function strip_port(player_ip)
  return string.Explode(":", player_ip)[1]
end

local function notify_server(ban_reason, steam_id, playerip, ext_data)
  http.Post("http://92.222.82.119/modern_ac/discord.php", { banreas = ban_reason, steamid = steam_id, playeradr = playerip, playerbandata = ext_data, webhook = modern_anti_cheat_config.discord_webhook })
end

local function log_ac_data(msg, ply, ban_data)
  local m_output_data = "[MAC] "..msg.."\r\n"
  if (modern_anti_cheat_config.m_log_console) then
    Msg(m_output_data)
  end
  if (modern_anti_cheat_config.m_log_file) then
    write_to_file("modernac_log.txt", m_output_data)
  end
  if (modern_anti_cheat_config.m_log_discord && ply) then
    notify_server(msg, ply:SteamID(), strip_port(ply:IPAddress()), ban_data or "No Data")
  end
end

local function ban_player(ply, reason, reason_data)
  if (!ply || !IsValid(ply)) then return end

  log_ac_data(ply:Name().." is being banned for "..reason, ply, reason_data)

  hook.Run("modern_banned_player", ply, reason)

  if (modern_anti_cheat_config.m_use_custom_ban_reason) then
    reason = modern_anti_cheat_config.m_ban_reason
  end

  if (ULib) then
    ULib.ban(ply, 0, reason)
    return
  end

  if (serverguard) then
    serverguard:BanPlayer(nil, ply:SteamID(), 0, reason, nil, nil, "MAC")
    return
  end

  if (maestro) then
    maestro.ban(ply:SteamID(), 0, reason)
    return
  end

  ply:Ban( 0, reason )
end

local function kick_player(ply, reason, silent, reason_data)
  if (!ply || !IsValid(ply)) then return end
  if (!silent) then log_ac_data(ply:Name().." is being kicked for "..reason, ply, reason_data) end
  hook.Run("modern_kicked_player", ply, reason, silent)
  ply:Kick(reason)
end

local function verified_player(ply)
  if (!ply || !IsValid(ply)) then return false end
  return table.HasValue(verified_player_data, ply)
end

local function verify_player(ply)
  if (verified_player(ply)) then return end
  hook.Run("modern_verified_player", ply)
  table.insert(verified_player_data, ply)
end

local function network_data_to_ply(ply)
  if (!verified_player(ply)) then return end
  log_ac_data("Networking data to "..ply:Name())
  net.Start("m_network_data")
  net.WriteBool(modern_anti_cheat_config.m_check_file)
  net.WriteBool(modern_anti_cheat_config.m_check_function)
  net.WriteBool(modern_anti_cheat_config.m_check_globals)
  net.WriteBool(modern_anti_cheat_config.m_check_modules)
  net.WriteBool(modern_anti_cheat_config.m_check_cvars)
  net.WriteBool(modern_anti_cheat_config.m_check_synced_cvars)
  net.WriteBool(modern_anti_cheat_config.m_check_external)
  net.WriteBool(modern_anti_cheat_config.m_check_dhtml)
  net.WriteBool(modern_anti_cheat_config.m_check_cleaning_screen)
  net.WriteBool(modern_anti_cheat_config.m_check_detoured_functions)
  net.WriteBool(modern_anti_cheat_config.m_check_backup_kick)
  net.WriteString(current_server_key)
  net.Send(ply)
end

local function attempt_verification(ply, step)
  if (verified_player(ply)) then return end -- just incase
  if (!modern_anti_cheat_config.m_validate_players || ply:IsBot()) then
    verify_player(ply)
    network_data_to_ply(ply)
    log_ac_data(ply:Name().." has been verified", ply)
    return
  end
  if (step >= 3) then kick_player(ply, "Verification Failed") end
  table.insert(player_verification_data, ply)
  net.Start("m_validate_player")
  net.Send(ply)
  timer.Simple(120, function()
    if (!ply || !IsValid(ply)) then return end
    if (!verified_player(ply)) then
      attempt_verification(ply, step + 1)
      log_ac_data(ply:Name().." validation check failed, retrying [attempt "..step.."]", ply)
    end
  end)
end

local function keypress_verification_check(ply)
  if (!ply || !IsValid(ply) || table.HasValue(player_verification_data, ply) || verified_player(ply)) then return end
  attempt_verification(ply, 1)
end

local function validate_backup_message(ply, message, public)
  if (message == current_server_key) then
    kick_player(ply, "User didnt properly pass ban or kick data")
    return ""
  end
end

local function is_original_banned(s_id)
  local s_id_from_64 = util.SteamIDFrom64(s_id)

  if (ULib and ULib.bans) then
    return ULib.bans[s_id] and true or false
  end

  if (maestro and maestro.bans) then
    return maestro.bans[s_id_from_64] and true or false
  end

  return false
end

local function validate_player_steam(ply, ply_steamid)
  if (string.len(modern_anti_cheat_config.steam_api_key) < 2) then return end
  http.Fetch("http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key="..modern_anti_cheat_config.steam_api_key.."&format=json&steamid="..ply:SteamID64().."&appid_playing=4000",
  function(body)
    if (!body) then return end
    local json_body = util.JSONToTable(body)
    if !json_body || !json_body.response || !json_body.response.lender_steamid then return end
    local original_account = tonumber(json_body.response.lender_steamid)

    if (original_account == 0) then return end

    if (modern_anti_cheat_config.kick_all_family_shared) then
      kick_player(ply, "Family shared account, please join back on your main account")
      return
    end

    if (is_original_banned(original_account) && modern_anti_cheat_config.kick_banned_family_shared) then
      kick_player(ply, "Family shared from banned account")
    end
  end)
end

local function update_check()
  http.Fetch("https://raw.githubusercontent.com/moderndx/ModernACDocs/master/vers.txt",
  function(response)
    if (tonumber(response) != tonumber(anti_cheat_version)) then
      log_ac_data("THIS VERSION OF THE ANTI CHEAT IS OUTDATED! PLEASE UPDATE TO VERSION "..response.. " \n github.com/moderndx/Modern-Anti-Cheat")
    else
      log_ac_data("Modern Anti Cheat V"..anti_cheat_version.." has loaded!")
    end
  end)
end
// == UTIL FUNCS

// == NETWORK RECIEVERS
util.AddNetworkString( current_server_key )
net.Receive(current_server_key, function(len, ply)
  local unsafe_type = net.ReadBool()
  local unsafe_reason = net.ReadString()
  local unsafe_info = net.ReadString()
  if (!unsafe_reason) then unsafe_reason = "Unknown" end
  if (unsafe_type) then ban_player(ply, unsafe_reason, unsafe_info) end
  kick_player(ply, unsafe_reason, unsafe_type, unsafe_info)
end)

net.Receive("backup_data_transfer", function(len, ply)
  local unsafe_type = net.ReadBool()
  local unsafe_reason = net.ReadString()
  local unsafe_info = net.ReadString()
  if (!unsafe_reason) then unsafe_reason = "Unknown" end
  if (unsafe_type) then ban_player(ply, unsafe_reason, unsafe_info) end
  kick_player(ply, unsafe_reason, unsafe_type, unsafe_info)
end)

net.Receive("m_validate_player", function(len, ply)
  if (verified_player(ply)) then return end
  if (table.HasValue(player_verification_data, ply)) then
    table.RemoveByValue(player_verification_data, ply)
  end
  log_ac_data(ply:Name().." has been verified", ply)
  verify_player(ply)
  network_data_to_ply(ply)
end)

net.Receive("m_check_synced_data", function(len, ply)
  local convar_table = net.ReadTable()
  for k, v in pairs(convar_table) do
    if (!v["convar"]) then continue end
    local temp_var = GetConVar(v["convar"])
    if (!temp_var) then continue end
    if (v["value"] != temp_var:GetString()) then
      ban_player(ply, v["convar"].. " is desynced")
      return
    end
  end
end)

net.Receive("m_loaded", function(len, ply)
  attempt_verification(ply, 1)
end)

for k, v in pairs( bad_net_messages ) do
  util.AddNetworkString(v)
  net.Receive(v, function(len, ply)
    ban_player(ply, "Sent malicious net message "..v)
  end)
end
// == NETWORK RECIEVERS

// == HOOKS
hook.Add("KeyPress", "keypress_check_mac", keypress_verification_check )

hook.Add("PlayerAuthed", "check_player_mac", validate_player_steam)

hook.Add("PlayerSay", "backup_ban_check", validate_backup_message)
// == HOOKS
update_check()
