return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;
	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
		TimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"timeban", "tempban", "tban", "temporaryban"};
			Args = {"player", "number<s/m/h/d>", "reason"};
			Description = `Bans the target player(s) from the game for the supplied amount of time; data-persistent; undo using {Settings.Prefix}untimeban`;
			Filter = true;
			AdminLevel = "HeadAdmins";
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing target user (argument #1)")

				local duration, valid = assert(args[2], "Missing duration (argument #2)"):gsub("^(%d+)([smhd])$", function(val, unit)
					return if unit == "s" then val
						elseif unit == "m" then val * 60
						elseif unit == "h" then val * 60 * 60
						else val * 60 * 60 * 24
				end)
				assert(valid > 0, "Invalid duration value (argument #2)")

				local reason = args[3] or "No reason provided"

				for _, v in service.GetPlayers(plr, args[1], {
					IsKicking = true;
					NoFakePlayer = false;
					})
				do
					if Admin.CheckAuthority(plr, v, "time-ban", false) then
						Admin.AddTimeBan(v, duration, reason, plr)
						Functions.LogAdminAction(plr, "Time Ban", v.Name, `Duration: {args[2]}, Reason: {reason}`)
						Functions.Hint(`Time-banned {service.FormatPlayer(v, true)} for {args[2]}`, {plr})
					end
				end
			end
		};

		DirectTimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"directtimeban", "directtimedban", "directtempban", "directtban", "directtemporaryban"};
			Args = {"username(s)", "number<s/m/h/d>", "reason"};
			Description = `Bans the target user(s) from the game for the supplied amount of time; data-persistent; undo using {Settings.Prefix}untimeban`;
			Filter = true;
			AdminLevel = "HeadAdmins";
			Hidden = true;
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing target user (argument #1)")

				local duration, valid = assert(args[2], "Missing duration (argument #2)"):gsub("^(%d+)([smhd])$", function(val, unit)
					return if unit == "s" then val
						elseif unit == "m" then val * 60
						elseif unit == "h" then val * 60 * 60
						else val * 60 * 60 * 24
				end)
				assert(valid > 0, "Invalid duration value (argument #2)")

				local reason = args[3] or "No reason provided"

				for i in string.gmatch(args[1], "[^,]+") do
					local UserId = Functions.GetUserIdFromNameAsync(i)
					if UserId then
						if UserId == plr.UserId then
							Functions.Hint("You cannot ban yourself", {plr})
							continue
						end

						local getNameSuccess, actualName = pcall(service.Players.GetNameFromUserIdAsync, service.Players, UserId)

						Admin.AddTimeBan({UserId = UserId, Name = if getNameSuccess then actualName else i}, duration, reason, plr)
						Functions.LogAdminAction(plr, "Direct Time Ban", actualName or i, `Duration: {args[2]}, Reason: {reason}`)
						Functions.Hint(
							`Time-banned {if getNameSuccess then `@{actualName}` else `'{i}'`} for {args[2]}`,
							{plr}
						)
					else
						Functions.Hint(`No user named '{i}' exists (Please try again if you think this is an internal error)`, {plr})
					end
				end
			end
		};

		UnTimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"untimeban", "untimedban", "untban", "untempban", "untemporaryban"};
			Args = {"user"};
			Description = "Removes the target user(s) from the timebans list";
			AdminLevel = "HeadAdmins";
			Dangerous = true;
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target user (argument #1)"), {
					UseFakePlayer = true;
					AllowUnknownUsers = true;
					})
				do
					Functions.LogAdminAction(plr, "Un-Time Ban", v.Name, "Removed from timeban list")
					Functions.Hint(
						if Admin.RemoveTimeBan(v.Name)
							then `{service.FormatPlayer(v, true)} has been un-time-banned`
							else `{service.FormatPlayer(v, true)} is not currently time-banned`,
						{plr}
					)
				end
			end
		};

		PermanentBan = {
			Prefix = Settings.Prefix;
			Commands = {"globalban", "permban", "permanentban", "pban", "gameban", "gban"};
			Args = {"player/user", "reason"};
			Description = "Bans the target player(s) from the game permanently; if they join a different server they will be banned there too";
			AdminLevel = "HeadAdmins";
			Dangerous = true;
			Filter = true;
			Function = function(plr: Player, args: {string}, data: {})
				local reason = args[2] or "No reason provided"

				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target user (argument #1)"), {
					IsKicking = true;
					NoFakePlayer = false;
					})
				do
					if Admin.CheckAuthority(plr, v, "game-ban", false) then
						Admin.AddBan(v, reason, true, plr, "Global")
						Functions.LogAdminAction(plr, "Permanent Ban", v.Name, reason)
						Functions.Hint(`Game-banned {service.FormatPlayer(v, true)}`, {plr})
					else
						Functions.Hint(`Unable to game-ban {service.FormatPlayer(v, true)} (insufficient permission level)`, {plr})
					end
				end
			end
		};

		UnGameBan = {
			Prefix = Settings.Prefix;
			Commands = {"unglobalban", "unpermban", "unpermanentban", "unpban", "ungameban", "ungban"};
			Args = {"user"};
			Description = "Unbans the target user(s) from the game; saves";
			AdminLevel = "HeadAdmins";
			Dangerous = true;
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target user (argument #1)"), {
					UseFakePlayer = true;
					AllowUnknownUsers = true;
					})
				do
					Functions.LogAdminAction(plr, "Unbanned", v.Name, "N/A")
					Functions.Hint(
						if Admin.RemoveBan(v.Name, true)
							then `{service.FormatPlayer(v, true)} has been unbanned from the game`
							else `{service.FormatPlayer(v, true)} is not currently banned`,
						{plr}
					)
				end
			end
		};

		TempAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"tempadmin", "tadmin"};
			Args = {"player"};
			Description = "Makes the target player(s) a temporary admin; does not save";
			AdminLevel = "HeadAdmins";
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: any)
				local senderLevel = data.PlayerData.Level

				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target player (argument #1)")) do
					if senderLevel > Admin.GetLevel(v) then
						Admin.AddAdmin(v, "Admins", true)
						Functions.LogAdminAction(plr, "Temporary Admin", v.Name, "Temporary admin granted.")
						Functions.Notification("Notification", "You are a temp administrator. Click to view commands.", {v}, 10, "MatIcon://Admin panel settings", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v, true)} is now a temporary admin`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v, true)} is already the same admin level as you or higher`, {plr})
					end
				end
			end
		};

		Admin = {
			Prefix = Settings.Prefix;
			Commands = {"permadmin", "padmin", "admin"};
			Args = {"player/user"};
			Description = "Makes the target player(s) an admin; saves";
			AdminLevel = "HeadAdmins";
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: any)
				local senderLevel = data.PlayerData.Level

				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target user (argument #1)"), {
					UseFakePlayer = true;
					})
				do
					if senderLevel > Admin.GetLevel(v) then
						Admin.AddAdmin(v, "Admins")
						Functions.LogAdminAction(plr, "Permanent Admin", v.Name, "Granted permanent admin rights.")
						Functions.Notification("Notification", "You are an administrator. Click to view commands.", {v}, 10, "MatIcon://Admin panel settings", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v, true)} is now a permanent admin`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v, true)} is already the same admin level as you or higher`, {plr})
					end
				end
			end
		};

		GlobalMessage = {
			Prefix = Settings.Prefix;
			Commands = {"globalmessage", "gm", "globalannounce"};
			Args = {"message"};
			Description = "Sends a global message to all servers";
			AdminLevel = "HeadAdmins";
			Filter = true;
			IsCrossServer = true;
			CrossServerDenied = true;
			Function = function(plr: Player, args: {string})
				if not Core.CrossServer("Message", plr.Name, assert(args[1], "Missing message")) then
					error("CrossServer handler not ready; please try again later")
				end
			end;
		};

		GlobalTimeMessage = {
			Prefix = Settings.Prefix;
			Commands = {"gtm", "globaltimedmessage", "globaltimemessage", "globaltimem"};
			Args = {"time", "message"};
			Description = "Sends a global message to all servers and makes it stay on the screen for the amount of time (in seconds) you supply";
			AdminLevel = "HeadAdmins";
			Filter = true;
			IsCrossServer = true;
			CrossServerDenied = true;
			Function = function(plr: Player, args: {string})
				if not Core.CrossServer("Message", plr.Name, assert(args[2], "Missing message"), assert(args[1], "Missing time amount")) then
					error("CrossServer handler not ready; please try again later")
				end
			end;
		};

		FullClear = {
			Prefix = Settings.Prefix;
			Commands = {"fullclear", "clearinstances", "fullclr"};
			Args = {};
			Description = "Removes any instance created server-side by Adonis; May break things";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				local objects = service.GetAdonisObjects()
				for i, v in objects do
					v:Destroy()
				end
				table.clear(objects)

				--for i, v in Functions.GetPlayers() do
				--	Remote.Send(v, "Function", "ClearAllInstances")
				--end
			end
		};

		BackupMap = {
			Prefix = Settings.Prefix;
			Commands = {"backupmap", "mapbackup", "bmap"};
			Args = {};
			Description = "Changes the backup for the restore map command to the map's current state";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				local plr_name = if plr then service.FormatPlayer(plr) else "%SYSTEM%"

				if plr then
					Functions.Hint("Updating Map Backup...", {plr})
				end

				if Variables.BackingupMap then
					error("Backup Map is in progress. Please try again later!")
					return
				end
				if Variables.RestoringMap then
					error("Cannot backup map while map is being restored!")
					return
				end

				Variables.BackingupMap = true
				Variables.OriginalGravity = workspace.Gravity

				local Lighting = service.Lighting
				local atmosphere = Lighting:FindFirstChildWhichIsA("Atmosphere")

				Variables.OriginalLightingSettings = {
					Ambient = Lighting.Ambient,
					OutdoorAmbient = Lighting.OutdoorAmbient,
					Brightness = Lighting.Brightness,
					TimeOfDay = Lighting.TimeOfDay,
					FogColor = Lighting.FogColor,
					FogEnd = Lighting.FogEnd,
					FogStart = Lighting.FogStart,
					GlobalShadows = Lighting.GlobalShadows,
					Outlines = Lighting.Outlines,
					ShadowColor = Lighting.ShadowColor,
					ColorShift_Bottom = Lighting.ColorShift_Bottom,
					ColorShift_Top = Lighting.ColorShift_Top,
					GeographicLatitude = Lighting.GeographicLatitude,
					Name = Lighting.Name,
					Sky = Lighting:FindFirstChildOfClass("Sky") and Lighting:FindFirstChildOfClass("Sky"):Clone(),
				}
				Variables.OriginalAtmosphereSettings = {
					Name = atmosphere and atmosphere.Name,
					Density = atmosphere and atmosphere.Density,
					Offset = atmosphere and atmosphere.Offset,
					Color = atmosphere and atmosphere.Color,
					Decay = atmosphere and atmosphere.Decay,
					Glare = atmosphere and atmosphere.Glare,
					Haze = atmosphere and atmosphere.Haze,
				}

				local tempmodel = service.New("Model", {
					Name = "BACKUP_MAP_MODEL"
				})
				for _, v in workspace:GetChildren() do
					if v.ClassName ~= "Terrain" and not service.Players:GetPlayerFromCharacter(v) then
						local archive = v.Archivable
						v.Archivable = true
						v:Clone().Parent = tempmodel
						v.Archivable = archive
					end
				end
				Variables.MapBackup = tempmodel:Clone()
				tempmodel:Destroy()

				local Terrain = workspace.Terrain or workspace:FindFirstChildOfClass("Terrain")
				if Terrain then
					Variables.TerrainMapBackup = Terrain:CopyRegion(Terrain.MaxExtents)
				end

				if plr then
					Functions.Hint('Backup Complete', {plr})
				end

				Variables.BackingupMap = false

				Logs.AddLog(Logs.Script, {
					Text = "Backup Complete";
					Desc = `{plr_name} has successfully backed up the map.`;
				})
			end
		};

		PromptInvite = {
			Prefix = Settings.Prefix;
			Commands = {"promptinvite", "inviteprompt", "forceinvite"};
			Args = {"player"};
			Description = "Opens the friend invitation popup for the target player(s), same as them running !invite";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					service.SocialService:PromptGameInvite(v)
				end
			end
		};

		ForceRejoin = {
			Prefix = Settings.Prefix;
			Commands = {"forcerejoin"};
			Args = {"player"};
			Description = `Forces target player(s) to rejoin the server; same as them running {Settings.PlayerPrefix}rejoin`;
			NoStudio = true;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				local players = service.GetPlayers(plr, args[1])
				local teleportOptions = service.New("TeleportOptions", {
					ServerInstanceId = game.JobId
				})
				service.TeleportService:TeleportAsync(game.PlaceId, players, teleportOptions)
			end
		};

		FullShutdown = {
			Prefix = Settings.Prefix;
			Commands = {"fullshutdown", "globalshutdown"};
			Args = {"reason"};
			Description = "Initiates a shutdown for every running game server";
			AdminLevel = "HeadAdmins";
			Filter = true;
			IsCrossServer = true;
			Function = function(plr: Player, args: {string})
				assert(args[1], "Reason (argument #1) must be supplied for this command!")

				if
					Remote.GetGui(plr, "YesNoPrompt", {
						Question = `Shutdown all running servers for the reason '{args[1]}'?`;
						Title = "Global Shutdown";
					}) == "Yes"
				then
					assert(
						Core.CrossServer(
							"NewRunCommand",
							{
								Name = plr.Name,
								UserId = plr.UserId,
								AdminLevel = Admin.GetLevel(plr)
							},
							`{Settings.Prefix}shutdown {args[1]}\n\n\n[GLOBAL SHUTDOWN]`
						),
						"An error has occured"
					)
				end
			end;
		};
	}
end
