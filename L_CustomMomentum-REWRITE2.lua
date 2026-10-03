-- Hey, so you should hit CTRL+F or the equivalent for your OS, and then type "@" followed by a number, with that you can quickly explore the code.

freeslot("S_PLAY_ALTFALL")
states[S_PLAY_ALTFALL] = {
	sprite = SPR_PLAY,
	frame = SPR2_FALL,
	tics = 2,
	action = nil,
	var1 = 0,
	var2 = 0,
	nextstate = S_PLAY_ALTFALL
}

-- @1 PRINT TEXT UPON LOADING --
print("\x83" + "[CONFIRM]:" + "\x80" + "CustomMomentum-REWRITE2 for 2.2.X by LowPolyDX!")
print("\x82" + "[NOTICE]:" + "\x80" + "Please enjoy and report issues to the relevant MB Discussion thread.")
print("\x82" + "[NOTICE]:" + "\x80" + "Feel free to also leave a review for the addon on the MB.")

local debug = true

-- @2 FUNCTIONS --
rawset(_G, "P_IsValidPlayer", function(p)
	return p and p.valid and p.mo and p.mo.valid and p.playerstate == PST_LIVE and p.mo.health >= 1
end)

rawset(_G, "P_IsSuperOrSneakers", function(p)
	if not P_IsValidPlayer(p) then return false end
	if (p.powers[pw_super] or p.powers[pw_sneakers]) then
		return true
	else
		return false
	end
end)

rawset(_G, "P_IsUnderwater", function(p)
	if not P_IsValidPlayer(p) then return false end
    if (p.mo.eflags & MFE_UNDERWATER or p.powers[pw_underwater]) then
        return true
	else
		return false
	end
end)

rawset(_G, "P_IsTwoD", function(p)
	if not P_IsValidPlayer(p) then return false end
	if (twodlevel == true or p.mo.flags2 & MF2_TWOD ~= 0) then
		return true
	else
		return false
	end
end)

-- @3 MOMENTUM + PHYSICS --
addHook("PlayerThink", function(p)
	if not P_IsValidPlayer(p) then return false end

	local mo = p.mo
	mo.truespeed = FixedDiv(FixedHypot(mo.momx - p.cmomx, mo.momy - p.cmomy), mo.scale)
	mo.defspeed = skins[mo.skin].normalspeed
	mo.lastz = $ or 0
	mo.lastground = $ or 0
	mo.abiltime = $ or 0
	mo.jumpboosted = $ or false
	local slope = (mo.z*P_MobjFlip(mo) - mo.lastz*P_MobjFlip(mo))
	local jumpboost = (slope + (mo.truespeed/3)/3)/3

	if P_IsSuperOrSneakers(p) then
		mo.defspeed, mo.truespeed = mo.defspeed*5/4, mo.truespeed*3/5
	end
	if P_IsUnderwater(p) then
		mo.defspeed, jumpboost, mo.truespeed = (mo.defspeed*2), jumpboost/2, (mo.truespeed*2)
	end
	if P_IsTwoD(p) then
		mo.defspeed, jumpboost, mo.truespeed = mo.defspeed, jumpboost*2/3, mo.truespeed*2/3
	end
	if mo.z*P_MobjFlip(mo) > mo.lastz*P_MobjFlip(mo)
	and mo.standingslope ~= nil
	and not (p.mo.eflags & MFE_JUSTHITFLOOR)
	and P_IsObjectOnGround(mo) then
		p.normalspeed = $1 - ((slope)/25)
	end
	if mo.z*P_MobjFlip(mo) < mo.lastz*P_MobjFlip(mo)
	and mo.standingslope ~= nil
	and not (p.mo.eflags & MFE_JUSTHITFLOOR)
	and P_IsObjectOnGround(mo) then
		p.normalspeed = $1 - ((slope)/25)
	end
	if mo.truespeed < mo.defspeed
	and not (p.pflags & PF_GLIDING) then
		p.normalspeed = mo.defspeed
	end
	if not (p.mo.eflags & MFE_JUSTHITFLOOR)
	and P_IsObjectOnGround(mo) then
		mo.jumpboosted = false
	end
	if (p.pflags & PF_JUMPED)
	and mo.standingslope ~= nil
	and mo.z*P_MobjFlip(mo) > mo.lastz*P_MobjFlip(mo)
	and mo.lastground and not mo.jumpboosted
	and not (mo.eflags & MFE_JUSTHITFLOOR)
	and mo.truespeed > mo.defspeed
	and not P_IsObjectOnGround(mo) then
		mo.momz, mo.jumpboosted = $1 + jumpboost, true
	else
		mo.momz = mo.momz
	end
	local dashdude = p.charflags & SF_DASHMODE
	if dashdude and p.dashmode >= 3*TICRATE
	and leveltime % 15 == 0 then
		p.normalspeed = $1 + ((p.dashmode/35)*FU)
	end
	if mo.truespeed < p.normalspeed - 15*FU
	and not (p.pflags & PF_GLIDING)
	and mo.truespeed > mo.defspeed then
		p.normalspeed = max(p.normalspeed - 15*FU, max(mo.truespeed, mo.defspeed))
	end
	if mo.truespeed > p.normalspeed + FU
	and not (p.pflags & PF_GLIDING)
	and mo.truespeed > mo.defspeed then
		p.normalspeed = max(p.normalspeed + FU/6, max(mo.truespeed, mo.defspeed))
	end
	mo.prevmom = $==nil and {x=0,y=0,z=0} or $
	local pvm = mo.prevmom
	if mo.state == S_PLAY_FALL and not p.followitem == MT_TAILSOVERLAY then
		mo.state, p.panim = S_PLAY_ALTFALL, PA_FALL
	end
	mo.lastz = mo.z
	mo.lastground = P_IsObjectOnGround(mo)
end)

-- @5 DEBUG --
hud.add(function(v, p)
	local mo = p.mo
    if P_IsValidPlayer(p)
	and debug == true then
        v.drawString(300, 41, "DSPD: " .. (mo.defspeed/FU), V_ALLOWLOWERCASE | V_SNAPTOBOTTOM, "center")
		v.drawString(300, 31, "SPD: " .. (mo.truespeed/FU), V_ALLOWLOWERCASE | V_SNAPTOBOTTOM, "center")
		v.drawString(300, 21, "NSPD: " .. (p.normalspeed/FU), V_ALLOWLOWERCASE | V_SNAPTOBOTTOM, "center")
		v.drawString(300, 11, "DIFFZ: " .. ((mo.z - mo.lastz)/FU), V_ALLOWLOWERCASE | V_SNAPTOBOTTOM, "center")
    end
end)

-- @6 SONIC CHANGES --
addHook("AbilitySpecial", function(player)
	if player.mo.skin != "sonic"
		return
	end
	if player.pflags&PF_THOKKED
		return true
	end
	local actionspd = max(player.mo.truespeed + (10*FU + FU/2), (player.actionspd/2) + 12*FU)
	if player.mo.eflags & MFE_UNDERWATER
		actionspd = $/2
	end
	if P_IsTwoD(player) then
		P_InstaThrust(player.mo, player.drawangle, actionspd*2/3)
	else
		P_InstaThrust(player.mo, player.mo.angle, actionspd)
	end
	P_SpawnThokMobj(player)
	S_StartSound(player.mo, sfx_thok)
	player.pflags = $|PF_THOKKED
	return true
end)

-- @7 KNUCKLES CHANGES --
addHook("PlayerThink", function(p)
	local mo = p.mo
	if mo.skin != "knuckles"
		return
	end
	if mo.skin == "knuckles"
		p.charflags = $|SF_MULTIABILITY
	end
	if P_IsObjectOnGround(mo) and p.pflags & PF_GLIDING then
		p.pflags = $ & ~(PF_GLIDING|PF_JUMPED|PF_NOJUMPDAMAGE)
		p.mo.state = S_PLAY_WALK
	end
	p.skidtime = 0
	mo.prevmom = $==nil and {x=0,y=0,z=0} or $
	local pvm = mo.prevmom
	if mo.state == S_PLAY_GLIDE_LANDING then
		p.pflags = $ & ~(PF_GLIDING|PF_JUMPED|PF_NOJUMPDAMAGE|PF_STASIS)
		mo.state = S_PLAY_WALK
		mo.momx, mo.momy, mo.momz = pvm.x, pvm.y, pvm.z
	else
		pvm.x, pvm.y, pvm.z = mo.momx, mo.momy, mo.momz
	end
end)

addHook("PlayerThink", function(player)
	if player.mo.skin != "knuckles"
		return
	end
	local actionspd = (player.mo.truespeed + FU/2)
	if player.mo.eflags & MFE_UNDERWATER
		actionspd = $/2
	end
	if player.pflags&PF_GLIDING then
		P_InstaThrust(player.mo, player.drawangle, actionspd)
	end
end)