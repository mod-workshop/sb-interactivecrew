local oldinit = init
local oldTriggerCombatBenefits = triggerCombatBenefits

function init()
	oldinit()
	message.setHandler("player.getCompanions", simpleHandler(getCompanions))
	message.setHandler("recruits.requestHoldPosition", simpleHandler(requestHoldPosition))
	message.setHandler("recruits.requestLounge", simpleHandler(requestLounge))
end

function getCompanions()
    return playerCompanions.getCompanions("followers")
end

function requestHoldPosition(uniqueId, recruitUuid, targetPosition)
	if not onOwnShip() then
		local recruit = recruitSpawner:getRecruit(recruitUuid)
		if not recruit then return end
		world.sendEntityMessage(uniqueId, "recruit.confirmHoldPositionBehavior", targetPosition)
	else
		recruitSpawner:recruitUnfollowing(onOwnShip(), recruitUuid)
		world.sendEntityMessage(uniqueId, "recruit.confirmHoldPosition", targetPosition)
	end
end

function requestLounge(uniqueId, recruitUuid, loungeableId)
	if not onOwnShip() then
		local recruit = recruitSpawner:getRecruit(recruitUuid)
		if not recruit then return end
		world.sendEntityMessage(uniqueId, "recruit.confirmLoungeBehavior", loungeableId)
	else
		recruitSpawner:recruitUnfollowing(onOwnShip(), recruitUuid)
		world.sendEntityMessage(uniqueId, "recruit.confirmLounge", loungeableId)
	end
end

function triggerCombatBenefits(recruitUuid)
	oldTriggerCombatBenefits(recruitUuid)
end
