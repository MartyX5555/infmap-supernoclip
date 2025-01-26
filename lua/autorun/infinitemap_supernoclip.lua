-- DISCLAIMER: VERY PROTOTYPE CONCEPT.

if CLIENT then

	CreateClientConVar("infmap_supernoclip_enable", 0, true, true, "enables/disables the supernoclip mode", 0, 1 )
	CreateClientConVar("infmap_supernoclip_speedmultipler", 1, true, true, "Sets the noclip speed multipler. Higher = faster. Shift/Ctrl speeds are adjusted accordingly.", 1 )
	CreateClientConVar("infmap_supernoclip_inheritspeed", 0, true, true, "enables/disables if the noclip speed should be inherited to the player once he leaves the noclip. WARNING: THIS IS TRULY UNRELIABLE WITH A 750+ MULTIPLER!!!", 0, 1)
end

local NoClipPlayers = {}

local function InitList()
	for k, ply in ipairs(player.GetHumans()) do
		NoClipPlayers[ply:SteamID()] = nil
	end
end
InitList()

hook.Remove( "PlayerNoClip", "InfMap_SuperNoclip_Checker")
hook.Add( "PlayerNoClip", "InfMap_SuperNoclip_Checker", function( ply, desiredNoClipState )
	if SERVER then
		NoClipPlayers[ply:SteamID()] = desiredNoClipState
	else
		if ply == LocalPlayer() then
			ply.InfMapIsOnNoclip = desiredNoClipState
		end
	end
end )

hook.Add("Tick", "InfMap_SuperNoclip_Tick", function()

	-- Clamp the multipler to sublight speeds, if the map is NOT infinite. Avoids engine breaking the noclip if too high
	local MultLimit = math.huge
	if not string.StartsWith(game.GetMap(), "gm_infmap") then
		MultLimit = 1000
	end

	if SERVER then
		for k, ply in ipairs(player.GetHumans()) do
			if ply:GetInfoNum( "infmap_supernoclip_enable", 0 ) == 0 then continue end
			if not NoClipPlayers[ply:SteamID()] then continue end -- only noclip players
			if not ply:Alive() or ply:InVehicle() then NoClipPlayers[ply:SteamID()] = nil continue end -- yes, for some reason, it could noclip while seated

			local CurPos = ply:GetPos()
			local Dir = ply:GetVelocity():GetNormalized()
			local Power = math.min(ply:GetInfoNum( "infmap_supernoclip_speedmultipler", 1 ), MultLimit) -- 10000000000

			local W = ply:KeyDown(IN_FORWARD)
			local A = ply:KeyDown(IN_MOVELEFT)
			local S = ply:KeyDown(IN_BACK)
			local D = ply:KeyDown(IN_MOVERIGHT)
			local Space = ply:KeyDown(IN_JUMP)
			local Shift = ply:KeyDown(IN_SPEED)
			local Ctrl = ply:KeyDown(IN_DUCK)

			if Shift then
				Power = Power * 5
			elseif Ctrl then
				Power = Power / 5
			end

			local NextPos = CurPos + Dir * Power
			if W or A or S or D or Space then
				ply:SetPos( NextPos )
			end

			-- Player Velocity calculation
			ply.NoclipVelocity = (NextPos - CurPos) / FrameTime()
		end
	else
		-- for prediction purposes
		local ply = LocalPlayer()
		if GetConVar("infmap_supernoclip_enable"):GetInt() == 0 then return end
		if not ply.InfMapIsOnNoclip then return end -- only noclip players
		if not ply:Alive() or ply:InVehicle() then ply.InfMapIsOnNoclip = nil return end -- yes, for some reason, it could noclip while seated

		local CurPos = ply:GetPos()
		local Dir = ply:GetVelocity():GetNormalized()
		local Power = math.min(GetConVar("infmap_supernoclip_speedmultipler"):GetFloat(), MultLimit)  -- 10000000000

		local W = ply:KeyDown(IN_FORWARD)
		local A = ply:KeyDown(IN_MOVELEFT)
		local S = ply:KeyDown(IN_BACK)
		local D = ply:KeyDown(IN_MOVERIGHT)
		local Space = ply:KeyDown(IN_JUMP)
		local Shift = ply:KeyDown(IN_SPEED)
		local Ctrl = ply:KeyDown(IN_DUCK)

		if Shift then
			Power = Power * 5
		elseif Ctrl then
			Power = Power / 5
		end

		-- Player Velocity calculation
		local NextPos = CurPos + Dir * Power
		if W or A or S or D or Space then
			ply:SetPos( NextPos )
		end
	end

end)

-- Controls exit velocity
hook.Remove("Move", "InfMap_SuperNoclip_Move")
hook.Add( "Move", "InfMap_SuperNoclip_Move", function( ply, mv, usrcmd )
	if not SERVER then return end
	if ply:GetInfoNum( "infmap_supernoclip_enable", 0 ) == 0 then return end
	if ply:GetInfoNum( "infmap_supernoclip_inheritspeed", 0) == 0 then return end
	if NoClipPlayers[ply:SteamID()] then return end
	if not isvector(ply.NoclipVelocity) then return end

	mv:SetVelocity( ply.NoclipVelocity )
	ply.NoclipVelocity = nil

end )