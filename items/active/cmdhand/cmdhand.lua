require "/scripts/messageutil.lua"
require "/items/active/weapons/weapon.lua"

local toggleFollowMessage = "recruit.toggleFollow"
local HoldPositionMessage = "recruit.holdPosition"
local loungeMessage = "recruit.lounge"
local operateMessage = "recruit.operate"
local useSkillMessage = "recruit.useSkill"
local setTargetMessage = "recruit.setTarget"

idleStance = {
	armRotation = 0,
	weaponRotation = 0,
	twoHanded = false,
	allowRotate = true,
	allowFlip = true
}

function init()
	self.weapon = Weapon:new()
	self.weapon:setStance(idleStance)
	self.weapon:init()
end

function activate(fireMode, shiftHeld)
  local followers = world.sendEntityMessage(player.id(),"player.getFollowerIds"):result()
	local commandedFollower = nil

	if fireMode == "primary" then
		if shiftHeld and followers[2] ~= nil then
			commandedFollower = followers[2]
		elseif followers[1] ~= nil then
			commandedFollower = followers[1]
		end
	elseif fireMode == "alt" then
		if shiftHeld and followers[4] ~= nil then
			commandedFollower = followers[4]
		elseif followers[3] ~= nil then
			commandedFollower = followers[3]
		end
	end

	if commandedFollower ~= nil then
		local aimPosition = activeItem.ownerAimPosition()
		local command = interpretCommand(commandedFollower, aimPosition)
		
		if command ~= "" then 
			commandCrewmate(command)
		end
	end
end

function interpretCommand(followerId, position)
	local targetEntityId = world.entityQuery(position, 1.0, { includedTypes = { "creature" } })[1]
  sb.logInfo("ic.cmdhand.interpretCommand > followerId: "..sb.print(followerId))

	if targetEntityId ~= nil then
	  local targetUniqueId = world.entityUniqueId(targetEntityId)
    sb.logInfo("ic.cmdhand.interpretCommand > Target ("..targetEntityId..") name: "..sb.print(world.entityName(targetEntityId))..", unique Id: "..sb.print(targetUniqueId))

		if targetEntityId == player.id() then
			return { followerId = followerId, message = toggleFollowMessage, args = { } }
		elseif targetUniqueId == followerId then
			return { followerId = followerId, message = useSkillMessage, args = { } }
		elseif entity.isValidTarget(targetEntityId) then
			return { followerId = followerId, message = setTargetMessage, args = { attackTargetId = targetEntityId } }
		end
	else
		targetEntityId = world.objectAt(position)
		
		if targetEntityId ~= nil then
			local objectType = world.getObjectParameter(targetEntityId, "category")
			
			if objectType == "wire" or objectType == "light" then
				return { followerId = followerId, message = operateMessage, args = { targetEntityId = targetEntityId } }
			elseif world.getObjectParameter(targetEntityId, "objectType") == "loungeable" then
				return { followerId = followerId, message = loungeMessage, args = { targetEntityId = targetEntityId } }
			end
		else
			return { followerId = followerId, message = HoldPositionMessage, args = { targetPosition = position } }
		end
	end
	
	return ""
end

function commandCrewmate(command)
  sb.logInfo("cmdhand.commandCrewmate > Sending command: "..sb.print(command))
	world.sendEntityMessage(command.followerId, command.message, command.args)
end

function update(dt, fireMode, shiftHeld)
	self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
	self.weapon:uninit()
end
