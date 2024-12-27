return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Admin, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti

	if env then setfenv(1, env) end

	local Routine = env.Routine
	local Pcall = env.Pcall

	return {
		CharGear = {
			Prefix = Settings.Prefix;
			Commands = {"chargear", "charactergear", "doll", "cgear", "playergear", "dollify", "pgear", "plrgear"};
			Args = {"player/username", "steal"};
			Fun = true;
			AdminLevel = "Moderators";
			Description = "Gives you a doll of a player";
			Function = function(plr: Player, args: {string})
				local plrChar = assert(plr.Character, "You don't have a character")
				local cfr = assert(plrChar:FindFirstChild("RightHand") or plrChar:FindFirstChild("Right Arm"), "You don't have a right hand/arm").CFrame
				local steal = args[2] and table.find({"yes", "y", "true"}, args[2]:lower())
				assert(args[2] == nil or table.find({"yes", "y", "true", "no", "n", "false"}, args[2]:lower()), "Invalid boolean argument type")

				for _, v in service.GetPlayers(plr, args[1], {UseFakePlayer = true}) do
					Routine(function()
						local targetName = service.Players:GetNameFromUserIdAsync(v.UserId)

						local tool = service.New("Tool", {
							Name = targetName;
							ToolTip = `@{targetName} as a tool`;
						})
						local handle = service.New("Part", {
							Parent = tool;
							Name = "Handle";
							CanCollide = false;
							Transparency = 1;
						})

						local orgHumanoid = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
						local model = service.Players:CreateHumanoidModelFromDescription(
							orgHumanoid and orgHumanoid:GetAppliedDescription() or service.Players:GetHumanoidDescriptionFromUserId(v.CharacterAppearanceId > 0 and v.CharacterAppearanceId or v.UserId),
							orgHumanoid and orgHumanoid.RigType or Enum.HumanoidRigType.R15
						)

						model.Name = targetName

						local hum = model:FindFirstChildOfClass("Humanoid") or model:WaitForChild("Humanoid")

						if hum then
							if hum.RigType == Enum.HumanoidRigType.R15 then
								hum:WaitForChild("BodyHeightScale").Value /= 2
								hum:WaitForChild("BodyDepthScale").Value /= 2
								hum:WaitForChild("BodyWidthScale").Value /= 2

								for _, obj in model:GetDescendants() do
									if obj:IsA("BasePart") then
										obj.Massless = true
										obj.CanCollide = false
									end
								end
							elseif hum.RigType == Enum.HumanoidRigType.R6 then
								local motors = {}
								table.insert(motors, model.HumanoidRootPart:FindFirstChild("RootJoint"))
								for _, motor in model.Torso:GetChildren() do
									if motor:IsA("Motor6D") then table.insert(motors, motor) end
								end
								for _, motor in motors do
									motor.C0 = CFrame.new((motor.C0.Position * 0.4)) * (motor.C0 - motor.C0.Position)
									motor.C1 = CFrame.new((motor.C1.Position * 0.4)) * (motor.C1 - motor.C1.Position)
								end

								for _, v in model:GetDescendants() do
									if v:IsA("BasePart") then
										v.Size *= 0.4
										v.Position = model.Torso.Position
									elseif v:IsA("Accessory") and v:FindFirstChild("Handle") then
										local handle = v.Handle
										handle.AccessoryWeld.C0 = CFrame.new((handle.AccessoryWeld.C0.Position * 0.4)) * (handle.AccessoryWeld.C0 - handle.AccessoryWeld.C0.Position)
										handle.AccessoryWeld.C1 = CFrame.new((handle.AccessoryWeld.C1.Position * 0.4)) * (handle.AccessoryWeld.C1 - handle.AccessoryWeld.C1.Position)
										local mesh = handle:FindFirstChildOfClass("SpecialMesh")
										if mesh then
											mesh.Scale *= 0.4
										end
									elseif v:IsA("SpecialMesh") and v.Parent.Name ~= "Handle" and v.Parent.Name ~= "Head" then
										v.Scale *= 0.4
									end
								end
							end
						end

						hum.PlatformStand = if steal then hum.PlatformStand else true

						model:PivotTo(cfr)
						handle.CFrame = cfr
						model.Animate.Disabled = true
						model.Parent = tool

						if v ~= plr then
							if steal then
								local orgCharacter = v.Character
								v.Character = model
								if orgCharacter and not service.IsDestroyed(orgCharacter) then
									orgCharacter:Destroy()
								end
							end
						end

						service.New("WeldConstraint", {
							Parent = tool;
							Part0 = handle;
							Part1 = model:FindFirstChild("Left Leg") or model:FindFirstChild("LeftFoot");
						})

						tool.Parent = plr:FindFirstChildWhichIsA("Backpack")
					end)
				end
			end
		};

		Sword = {
			Prefix = Settings.Prefix;
			Commands = {"sword", "givesword"};
			Args = {"player", "allow teamkill (default: true)"};
			Description = "Gives the target player(s) a sword";
			AdminLevel = "Moderators";
			Fun = true;
			Function = function(plr: Player, args: {string})
				local sword = service.Insert(125013769)
				local config = sword:FindFirstChild("Configurations")
				if config then
					config.CanTeamkill.Value = if args[2] and args[2]:lower() == "false" then false else true
				end
				for _, v in service.GetPlayers(plr, args[1]) do
					local Backpack = v:FindFirstChildOfClass("Backpack")
					if Backpack then
						sword:Clone().Parent = Backpack
					end
				end
			end
		};

		Dance = {
			Prefix = Settings.Prefix;
			Commands = {"dance"};
			Args = {"player"};
			Description = "Make the target player(s) dance";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChildOfClass("Humanoid") then
						local human = v.Character:FindFirstChildOfClass("Humanoid")
						local rigType = human and (human.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15") or nil
						Functions.PlayAnimation(v, rigType == "R6" and 27789359 or 507771019)
					end
				end
			end
		};

		BreakDance = {
			Prefix = Settings.Prefix;
			Commands = {"breakdance", "fundance", "lolwut"};
			Args = {"player"};
			Description = "Make the target player(s) break dance";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					task.spawn(Pcall, function()
						local color = ({"Really blue", "Really red", "Magenta", "Lime green", "Hot pink", "New Yeller", "White"})[math.random(1, 7)]
						local hum=v.Character:FindFirstChild("Humanoid")
						if not hum then return end
						--Remote.Send(v, "Function", "Effect", "dance")
						Admin.RunCommand(`{Settings.Prefix}sparkles`, v.Name, color)
						Admin.RunCommand(`{Settings.Prefix}fire`, v.Name, color)
						Admin.RunCommand(`{Settings.Prefix}nograv`, v.Name)
						Admin.RunCommand(`{Settings.Prefix}smoke`, v.Name, color)
						Admin.RunCommand(`{Settings.Prefix}spin`, v.Name)
						repeat hum.PlatformStand = true wait() until not hum or hum == nil or hum.Parent == nil
					end)
				end
			end
		};

		Hole = {
			Prefix = Settings.Prefix;
			Commands = {"hole", "sparta"};
			Args = {"player"};
			Description = "Sends the target player(s) down a hole";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for kay, player in service.GetPlayers(plr, args[1]) do
					Routine(function()
						local torso = player.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							local hole = service.New("Part", player.Character)
							hole.Anchored = true
							hole.CanCollide = false
							hole.Size = Vector3.new(10, 1, 10)
							hole.CFrame = torso.CFrame * CFrame.new(0,-3.3,-3)
							hole.BrickColor = BrickColor.new("Really black")
							local holeM = service.New("CylinderMesh", hole)
							torso.Anchored = true
							local foot = torso.CFrame * CFrame.new(0,-3, 0)
							for i = 1, 10 do
								torso.CFrame = foot * CFrame.fromEulerAnglesXYZ(-(math.pi/2)*i/10, 0, 0) * CFrame.new(0, 3, 0)
								task.wait(0.1)
							end
							for i = 1, 5, 0.2 do
								torso.CFrame = foot * CFrame.new(0,-(i^2), 0) * CFrame.fromEulerAnglesXYZ(-(math.pi/2), 0, 0) * CFrame.new(0, 3, 0)
								task.wait()
							end
							player.Character:BreakJoints()
						end
					end)
				end
			end
		};

		Lightning = {
			Prefix = Settings.Prefix;
			Commands = {"lightning", "smite"};
			Args = {"player"};
			Description = "Zeus strikes down the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					task.spawn(Pcall, function()
						local char = v.Character
						char.HumanoidRootPart.Anchored = true
						local zeus = service.New("Model", char)
						local cloud = service.New("Part", zeus)
						cloud.Anchored = true
						cloud.CanCollide = false
						cloud.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0, 25, 0)
						local sound = service.New("Sound", cloud)
						sound.SoundId = "rbxassetid://133426162"
						local mesh = service.New("SpecialMesh", cloud)
						mesh.MeshId = "http://www.roblox.com/asset/?id=1095708"
						mesh.TextureId = "http://www.roblox.com/asset/?id=1095709"
						mesh.Scale = Vector3.new(30, 30, 40)
						mesh.VertexColor = Vector3.new(0.3, 0.3, 0.3)
						local light = service.New("PointLight", cloud)
						light.Color = Color3.new(0, 85/255, 1)
						light.Brightness = 10
						light.Range = 30
						light.Enabled = false
						task.wait(0.2)
						sound.Volume = 0.5
						sound.Pitch = 0.8
						sound:Play()
						light.Enabled = true
						task.wait(1/100)
						light.Enabled = false
						task.wait(0.2)
						light.Enabled = true
						light.Brightness = 1
						task.wait(0.05)
						light.Brightness = 3
						task.wait(0.02)
						light.Brightness = 1
						task.wait(0.07)
						light.Brightness = 10
						task.wait(0.09)
						light.Brightness = 0
						task.wait(0.01)
						light.Brightness = 7
						light.Enabled = false
						task.wait(1.5)
						local part1 = service.New("Part", zeus)
						part1.Anchored = true
						part1.CanCollide = false
						part1.Size = Vector3.new(2, 9.2, 1)
						part1.BrickColor = BrickColor.new("New Yeller")
						part1.Transparency = 0.6
						part1.BottomSurface = "Smooth"
						part1.TopSurface = "Smooth"
						part1.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0, 15, 0)
						part1.Rotation = Vector3.new(0.359, 1.4, -14.361)
						task.wait()
						local part2 = part1:Clone()
						part2.Parent = zeus
						part2.Size = Vector3.new(1, 7.48, 2)
						part2.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0, 7.5, 0)
						part2.Rotation = Vector3.new(77.514, -75.232, 78.051)
						task.wait()
						local part3 = part1:Clone()
						part3.Parent = zeus
						part3.Size = Vector3.new(1.86, 7.56, 1)
						part3.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0, 1, 0)
						part3.Rotation = Vector3.new(0, 0, -11.128)
						sound.SoundId = "rbxassetid://130818250"
						sound.Volume = 1
						sound.Pitch = 1
						sound:Play()
						task.wait()
						part1.Transparency = 1
						part2.Transparency = 1
						part3.Transparency = 1
						service.New("Smoke", char.HumanoidRootPart).Color = Color3.new(0, 0, 0)
						char:BreakJoints()
					end)
				end
			end
		};

		Disco = {
			Prefix = Settings.Prefix;
			Commands = {"disco"};
			Args = {};
			Description = "Turns the place into a disco party";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				service.StopLoop("LightingTask")
				service.StartLoop("LightingTask", 0.5, function()
					local color = Color3.new(math.random(255)/255, math.random(255)/255, math.random(255)/255)
					Functions.SetLighting("Ambient", color)
					Functions.SetLighting("OutdoorAmbient", color)
					Functions.SetLighting("FogColor", color)
				end)
			end
		};

		Spin = {
			Prefix = Settings.Prefix;
			Commands = {"spin"};
			Args = {"player"};
			Description = "Makes the target player(s) spin";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local scr = Deps.Assets.Spinner:Clone()
				scr.Name = "SPINNER"
				local spinGryoAttachment = service.New("Attachment")
				spinGryoAttachment.Name = "ADONIS_SPIN_GYRO_ATTACHMENT"
				local spinGryo = service.New("AlignOrientation")
				spinGryo.Name = "ADONIS_SPIN_GYRO"
				spinGryo.MaxTorque = math.huge
				spinGryo.Responsiveness = 200
				spinGryo.Mode = Enum.OrientationAlignmentMode.OneAttachment
				spinGryo.AlignType = Enum.AlignType.PrimaryAxisPerpendicular
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						local humanoidRootPart = v.Character.HumanoidRootPart
						for _, q in humanoidRootPart:GetChildren() do
							if q.Name == "SPINNER" or q.Name == "ADONIS_SPIN_GYRO" or q.Name == "ADONIS_SPIN_GYRO_ATTACHMENT" then
								q:Destroy()
							end
						end
						spinGryoAttachment.Parent = humanoidRootPart
						spinGryo.Attachment0 = spinGryoAttachment
						spinGryo.CFrame = humanoidRootPart.CFrame
						spinGryo.Parent = humanoidRootPart
						local new = scr:Clone()
						new.Parent = humanoidRootPart
						new.Disabled = false
					end
				end
			end
		};

		UnSpin = {
			Prefix = Settings.Prefix;
			Commands = {"unspin"};
			Args = {"player"};
			Description = "Makes the target player(s) stop spinning";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						for _, q in v.Character.HumanoidRootPart:GetChildren() do
							if q.Name == "SPINNER" or q.Name == "SPINNER_GYRO" or q.Name == "ADONIS_SPIN_GYRO_ATTACHMENT" then
								q:Destroy()
							end
						end
					end
				end
			end
		};

		Trail = {
			Prefix = Settings.Prefix;
			Commands = {"trail", "trails"};
			Args = {"player", "textureid", "color"};
			Description = "Adds trails to the target's character's parts";
			AdminLevel = "Moderators";
			Fun = true;
			Function = function(plr, args)
				assert(#Functions.GetPlayers(plr, args[1]) > 0, "Player argument missing")

				local color = Functions.ParseColor3(args[3])
				local colorSequence = ColorSequence.new(color or Color3.new(1, 1, 1))

				if not color and args[3] and (args[3]:lower() == "truecolors" or args[3]:lower() == "rainbow") then
					colorSequence = ColorSequence.new{
						ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
						ColorSequenceKeypoint.new(1/7, Color3.fromRGB(255, 136, 0)),
						ColorSequenceKeypoint.new(2/7, Color3.fromRGB(255, 228, 17)),
						ColorSequenceKeypoint.new(3/7, Color3.fromRGB(135, 255, 7)),
						ColorSequenceKeypoint.new(4/7, Color3.fromRGB(11, 255, 207)),
						ColorSequenceKeypoint.new(5/7, Color3.fromRGB(10, 46, 255)),
						ColorSequenceKeypoint.new(6/7, Color3.fromRGB(255, 55, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 127))
					}
				end

				for _, v in Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					for _, p in char:GetChildren() do
						if p:IsA("BasePart") then
							Functions.RemoveParticle(p, "ADONIS_CMD_TRAIL")

							local attachment0 = p:FindFirstChild("ADONIS_TRAIL_ATTACHMENT0") or service.New("Attachment", {
								Parent = p;
								Name = "ADONIS_TRAIL_ATTACHMENT0";
							})
							local attachment1 = p:FindFirstChild("ADONIS_TRAIL_ATTACHMENT1") or service.New("Attachment", {
								Position = Vector3.new(0,-0.05,0);
								Parent = p;
								Name = "ADONIS_TRAIL_ATTACHMENT1";
							})
							Functions.NewParticle(p, "Trail", {
								Color = colorSequence;
								Texture = tonumber(args[2]) and `rbxassetid://{args[2]}`;
								TextureMode = "Stretch";
								TextureLength = 2;
								Attachment0 = attachment0;
								Attachment1 = attachment1;
								Name = "ADONIS_CMD_TRAIL";
							})
						end
					end
				end
			end;
		};

		Resize = {
			Prefix = Settings.Prefix;
			Commands = {"resize", "size", "scale"};
			Args = {"player", "mult"};
			Description = "Resize the target player(s)'s character by <mult>";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = math.clamp(tonumber(args[2]) or 1, 0.001, Variables.SizeLimit) -- Size limit exceeding over 20 would be unnecessary and may potientially create massive lag !!

				if not args[2] or not tonumber(args[2]) then
					num = 1
					Functions.Hint("Size changed to 1 [Argument #2 (size multiplier) wasn't supplied correctly.]", {plr})
				elseif tonumber(args[2]) and tonumber(args[2]) > Variables.SizeLimit then
					Functions.Hint(`Size changed to the maximum {num} [Argument #2 (size multiplier) went over the size limit]`, {plr})
				end

				local function fixDensity(char)
					for _, charPart in char:GetChildren() do
						if charPart:IsA("MeshPart") or charPart:IsA("Part") then
							local defaultprops = PhysicalProperties.new(charPart.Material)
							local density = defaultprops.Density / char:GetAttribute("Adonis_Resize") ^ 3

							charPart.CustomPhysicalProperties = PhysicalProperties.new(density, defaultprops.Friction, defaultprops.Elasticity)
						end
					end
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					local char = v.Character
					local human = char and char:FindFirstChildOfClass("Humanoid")

					if not human then
						Functions.Hint(`Cannot resize {service.FormatPlayer(v)}'s character: humanoid and/or character doesn't exist!`, {plr})
						continue
					end

					local resizeAttributeValue = char:GetAttribute("Adonis_Resize")
					if not resizeAttributeValue then
						char:SetAttribute("Adonis_Resize", num)
					elseif resizeAttributeValue * num < Variables.SizeLimit then
						char:SetAttribute("Adonis_Resize", resizeAttributeValue * num)
					else
						Functions.Hint(string.format("Cannot resize %s's character by %g%%: size limit exceeded.", service.FormatPlayer(v), num*100), {plr})
						continue
					end

					if human and char:IsA("Model") then
						char:ScaleTo(num)
					elseif human and human.RigType == Enum.HumanoidRigType.R15 then
						for _, val in human:GetChildren() do
							if val:IsA("NumberValue") and val.Name:match(".*Scale") then
								val.Value *= num
							end
						end
						fixDensity(char)
					elseif human and human.RigType == Enum.HumanoidRigType.R6 then
						local motors = {}
						table.insert(motors, char.HumanoidRootPart:FindFirstChild("RootJoint"))
						for _, motor in char.Torso:GetChildren() do
							if motor:IsA("Motor6D") then table.insert(motors, motor) end
						end
						for _, motor in motors do
							motor.C0 = CFrame.new((motor.C0.Position * num)) * (motor.C0 - motor.C0.Position)
							motor.C1 = CFrame.new((motor.C1.Position * num)) * (motor.C1 - motor.C1.Position)
						end

						for _, v in char:GetDescendants() do
							if v:IsA("BasePart") then
								v.Size *= num
							elseif v:IsA("Accessory") and v:FindFirstChild("Handle") then
								local handle = v.Handle
								handle.AccessoryWeld.C0 = CFrame.new((handle.AccessoryWeld.C0.Position * num)) * (handle.AccessoryWeld.C0 - handle.AccessoryWeld.C0.Position)
								handle.AccessoryWeld.C1 = CFrame.new((handle.AccessoryWeld.C1.Position * num)) * (handle.AccessoryWeld.C1 - handle.AccessoryWeld.C1.Position)
								local mesh = handle:FindFirstChildOfClass("SpecialMesh")
								if mesh then
									mesh.Scale *= num
								end
							elseif v:IsA("SpecialMesh") and v.Parent.Name ~= "Handle" and v.Parent.Name ~= "Head" then
								v.Scale *= num
							end
						end
						fixDensity(char)
					end
				end
			end
		};

		RopeConstraint = {
			Prefix = Settings.Prefix;
			Commands = {"rope", "chain"};
			Args = {"player1", "player2", "length"};
			Description = "Connects players using a rope constraint";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1] and args[2], "Missing player names (must specify two)")
				for i, player1 in service.GetPlayers(plr, args[1]) do
					for i2, player2 in service.GetPlayers(plr, args[2]) do
						local torso1 = player1.Character:FindFirstChild("HumanoidRootPart")
						local torso2 = player2.Character:FindFirstChild("HumanoidRootPart")
						if torso1 and torso2 then
							local att1 = service.New("Attachment", torso1)
							local att2 = service.New("Attachment", torso2)
							local rope = service.New("RopeConstraint", torso1)

							att1.Name = "Adonis_Rope_Attachment";
							att2.Name = "Adonis_Rope_Attachment";
							rope.Name = "Adonis_Rope_Constraint";

							rope.Visible = true
							rope.Attachment0 = att1
							rope.Attachment1 = att2
							rope.Length = tonumber(args[3]) or 20
						end
					end
				end
			end;
		};

		UnRopeConstraint = {
			Prefix = Settings.Prefix;
			Commands = {"unrope", "unchain"};
			Args = {"player"};
			Description = "UnRope";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, p in service.GetPlayers(plr, args[1]) do
					local torso = p.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						for i, v in torso:GetChildren() do
							if v.Name == "Adonis_Rope_Attachment" or v.Name == "Adonis_Rope_Constraint" then
								v:Destroy()
							end
						end
					end
				end
			end;
		};

		IceFreeze = {
			Prefix = Settings.Prefix;
			Commands = {"ice", "iceage", "icefreeze", "funfreeze"};
			Args = {"player"};
			Description = "Freezes the target player(s) in a block of ice";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							for _, obj in v.Character:GetChildren() do
								if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then obj.Anchored = true end
							end
							local ice = service.New("Part", v.Character)
							ice.BrickColor = BrickColor.new("Steel blue")
							ice.Material = "Ice"
							ice.Name = "Adonis_Ice"
							ice.Anchored = true
							--ice.CanCollide = false
							ice.TopSurface = "Smooth"
							ice.BottomSurface = "Smooth"
							ice.Size = Vector3.new(5, 6, 5)
							ice.Transparency = 0.3
							ice.CFrame = v.Character.HumanoidRootPart.CFrame
						end
					end)
				end
			end
		};

		Gear = {
			Prefix = Settings.Prefix;
			Commands = {"gear", "givegear"};
			Args = {"player", "id"};
			Description = "Gives the target player(s) a gear from the catalog based on the ID you supply";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local gearID = assert(tonumber(args[2]), "Invalid ID (not Number?)")
				local AssetIdType = service.MarketPlace:GetProductInfo(gearID).AssetTypeId

				if AssetIdType == 19 then
					local gear = service.Insert(gearID)

					if gear:IsA("BackpackItem") then
						service.New("StringValue", gear).Name = Variables.CodeName..gear.Name
						for i, v in service.GetPlayers(plr, args[1]) do
							if v:FindFirstChild("Backpack") then
								gear:Clone().Parent = v.Backpack
							end
						end
					end
				else
					error("Invalid ID provided, Not AssetType Gear.", 0)
				end
			end
		};

		Slippery = {
			Prefix = Settings.Prefix;
			Commands = {"slippery", "iceskate", "icewalk", "slide"};
			Args = {"player"};
			Description = "Makes the target player(s) slide when they walk";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local vel = service.New("BodyVelocity")
				vel.Name = "ADONIS_IceVelocity"
				vel.MaxForce = Vector3.new(5000, 0, 5000)
				local scr = Deps.Assets.Slippery:Clone()

				scr.Name = "ADONIS_IceSkates"

				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						local vel = vel:Clone()
						vel.Parent = v.Character.HumanoidRootPart
						local new = scr:Clone()
						new.Parent = v.Character.HumanoidRootPart
						new.Disabled = false
					end
				end

				scr:Destroy()
			end
		};

		UnSlippery = {
			Prefix = Settings.Prefix;
			Commands = {"unslippery", "uniceskate", "unslide"};
			Args = {"player"};
			Description = "Get sum friction all up in yo step";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						local scr = v.Character.HumanoidRootPart:FindFirstChild("ADONIS_IceSkates")
						local vel = v.Character.HumanoidRootPart:FindFirstChild("ADONIS_IceVelocity")
						if vel then vel:Destroy() end
						if scr then scr.Disabled = true scr:Destroy() end
					end
				end
			end
		};

		Trip = {
			Prefix = Settings.Prefix;
			Commands = {"trip"};
			Args = {"player", "angle"};
			Description = "Rotates the target player(s) by 180 degrees or a custom angle";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local angle = 130 or args[2]
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						v.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, 0, math.rad(angle))
					end
				end
			end
		};
	}
end
