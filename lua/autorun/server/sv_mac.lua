include("config/mac_config.lua")
// == NETWORKING
local m_network_strings = {"m_validate_player", "m_network_data", "m_check_synced_data", "m_loaded", "backup_data_transfer"}

// == NETWORKING

// == LOCAL DATA
local anti_cheat_version = "0.0.2"
local hashKey = "" // PM deadmonstor for a early version of the key.

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

local _M = modern_anti_cheat_config

current_server_key = generate_string(20)

table.insert(m_network_strings, current_server_key)

for k, v in pairs( m_network_strings ) do
	util.AddNetworkString( v )
end

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

local function notify_server(ban_reason, steam_id, playerip, ext_data) // For webviewer later on
	local ip,port = (GetConVarString('ip')),(GetConVarString('hostport'))
	
	ip = ip == "localhost" and "127.0.0.1" or ip
	
	local servername = tostring(GetHostName())
	http.Post("https://ac.thealterway.com/api/log", 
		{ hostname = servername, server = ip, port = port, banreas = ban_reason, steamid = steam_id, playeradr = playerip, playerbandata = ext_data, webhook = _M.discord_webhook },
		function( result ) 
			if result then
				local tabs = util.JSONToTable(result) 
				if type(tabs) == "table" and tabs["message"] then 
					ServerLog("[FMAC] Warning discord notify error. Error: "..tabs["message"].. " \r\n")
				end
			end
		end, 
		function( failed ) end, 
		{["Authorization"] = hashKey}
	)
end

local function log_ac_data(msg, ply, ban_data, shouldPrint)
	local m_output_data = "[FMAC] "..msg.."\r\n"
	if (_M.m_log_console) then
		Msg(m_output_data)
	end
	if (_M.m_log_file) then
		write_to_file("fmodernac_log.txt", m_output_data)
	end
	if (_M.m_log_discord && ply && (shouldPrint || false) && !(ply.isBeingBannedByAC or false)) then
		notify_server(msg, ply:SteamID64(), strip_port(ply:IPAddress()), ban_data or "No Data")
	end
end

local function ban_player(ply, reason, reason_data)
	if (!ply || !IsValid(ply) || (ply.isBeingBannedByAC or false)) then return end

	log_ac_data(ply:Name().." is being banned for having a "..reason, ply, reason_data, true)

	hook.Run("modern_banned_player", ply, reason)

	if (_M.m_use_custom_ban_reason) then
		reason = _M.m_ban_reason
	end
	
	ply.isBeingBannedByAC = true
	
	if modern_anti_cheat_config.developermode then return end
	
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
	if (!ply || !IsValid(ply) || (ply.isBeingKickedByAC or false)) then return end
	if (!silent) then log_ac_data(ply:Name().." is being kicked for "..reason, ply, reason_data, true) end
	hook.Run("modern_kicked_player", ply, reason, silent)
	
	ply.isBeingKickedByAC = true
	
	if modern_anti_cheat_config.developermode then return end
	
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
		net.WriteTable({_M.check_file, _M.m_check_function, _M.m_check_globals, _M.m_check_modules, _M.m_check_cvars, _M.m_check_synced_cvars, _M.m_check_external, _M.m_check_dhtml, _M.m_check_cleaning_screen, _M.m_check_detoured_functions, _M.m_check_backup_kick, current_server_key, _M.m_check_concommands, _M.m_fuck_aimbot})
	net.Send(ply)
end

local function attempt_verification(ply, step)

	if (verified_player(ply)) then return end
	
	if (!_M.m_validate_players || ply:IsBot()) then
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
	if (string.len(_M.steam_api_key) < 2) then return end
	http.Fetch("http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=".._M.steam_api_key.."&format=json&steamid="..ply:SteamID64().."&appid_playing=4000",
	function(body)
		if (!body) then return end
		local json_body = util.JSONToTable(body)
		if !json_body || !json_body.response || !json_body.response.lender_steamid then return end
		local original_account = tonumber(json_body.response.lender_steamid)

		if (original_account == 0) then return end

		if (_M.kick_all_family_shared) then
			kick_player(ply, "Family shared account, please join back on your main account")
			return
		end

		if (is_original_banned(original_account) && _M.kick_banned_family_shared) then
			kick_player(ply, "Family shared from banned account")
			return
		end
	end)
end

local function update_check()

	http.Fetch("https://gist.githubusercontent.com/DEADMONSTOR/1392e5c6c6f683dcb4fd3a1bb1fc3e5f/raw/FMac",
	function(response)

		local tabs = util.JSONToTable(response)

		if tabs and tabs["ver"] and (tostring(tabs["ver"]) != tostring(anti_cheat_version)) then
			tabs["changeLog"] = tabs["changeLog"] or "Unknown"
			log_ac_data("THIS VERSION OF THE ANTI CHEAT IS OUTDATED! PLEASE UPDATE TO VERSION "..tabs["ver"].. " \n https://github.com/deadmonstor/Modern-Anti-Cheat \n Changes: "..tabs["changeLog"])
		else
			log_ac_data("FModern Anti Cheat V"..anti_cheat_version.." has loaded!")
		end
	end)
	
end
// == UTIL FUNCS

// == NETWORK RECIEVERS
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
			ban_player(ply, v["convar"].. " is "..v["value"].." instead of "..temp_var:GetString())
			return
		end
	end
end)

net.Receive("m_loaded", function(len, ply)
	attempt_verification(ply, 1)
end)


for k, v in pairs( bad_net_messages ) do
	v = v:lower()
	if net.Receivers[v] then 
		local curNet = debug.getinfo(net.Receivers[v])
		if debug.getinfo(attempt_verification)["short_src"] != curNet["short_src"] then 
			log_ac_data(v.." has already been defined. Please check if this net message is exploitable "..curNet["short_src"].." Line: "..curNet["linedefined"]) 
			continue 
		end
	end
	
	util.AddNetworkString(v)
	net.Receive(v, function(len, ply)
		ban_player(ply, "Sent malicious net message "..v)
	end)
	
end
	
oldNetReceive = oldNetReceive or net.Receive

function net.Receive( ... )

	local tabs = {...}
	local curNet = debug.getinfo(tabs[2])
	tabs[1] = tabs[1]:lower()
	
	if table.HasValue(bad_net_messages, tabs[1]) and debug.getinfo(attempt_verification)["short_src"] != curNet["short_src"] then 
		log_ac_data(tabs[1].." has already been defined. Please check if this net message is exploitable "..curNet["short_src"].." Line: "..curNet["linedefined"])
	end
	
	oldNetReceive(...)

end

// == NETWORK RECIEVERS

// == HOOKS

hook.Add("KeyPress", "keypress_check_mac", keypress_verification_check )

hook.Add("PlayerAuthed", "check_player_mac", validate_player_steam)

hook.Add("PlayerSay", "backup_ban_check", validate_backup_message)

// == HOOKS

update_check()
