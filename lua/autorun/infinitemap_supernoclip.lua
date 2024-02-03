-- DISCLAIMER: VERY PROTOTYPE CONCEPT.

if CLIENT then

	CreateClientConVar("infmap_supernoclip_enable", 0, true, true, "enables/disables the supernoclip mode", 0, 1 )
	CreateClientConVar("infmap_supernoclip_speedmultipler", 0, true, true, "Sets the noclip speed multipler. Higher = faster. Shift/Ctrl speeds are adjusted accordingly.", 1 )

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

	if SERVER then
		for k, ply in ipairs(player.GetHumans()) do
			if ply:GetInfoNum( "infmap_supernoclip_enable", 0 ) == 0 then continue end
			if not NoClipPlayers[ply:SteamID()] then continue end -- only noclip players

			local CurPos = ply:GetPos()
			local Dir = ply:GetVelocity():GetNormalized()
			local Power = ply:GetInfoNum( "infmap_supernoclip_speedmultipler", 1 ) -- 10000000000

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

			if W or A or S or D or Space then
				print(ply:GetPhysicsObject())
				ply:SetPos( CurPos + Dir * Power )
			end
		end
	else

		local ply = LocalPlayer()
		if GetConVar("infmap_supernoclip_enable"):GetInt() == 0 then return end
		if not ply.InfMapIsOnNoclip then return end -- only noclip players

		local CurPos = ply:GetPos()
		local Dir = ply:GetVelocity():GetNormalized()
		local Power = GetConVar("infmap_supernoclip_speedmultipler"):GetInt() -- 10000000000

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

		if W or A or S or D or Space then
			ply:SetPos( CurPos + Dir * Power ) -- for prediction purposes
		end

	end

end)
