require "/scripts/messageutil.lua"

local oldrecruitableInit = recruitable.init

function recruitable.init()
	oldrecruitableInit()
	message.setHandler("recruit.confirmHoldPosition", simpleHandler(recruitable.confirmHoldPosition))
	message.setHandler("recruit.confirmHoldPositionBehavior", simpleHandler(recruitable.confirmHoldPositionBehavior))
	message.setHandler("recruit.confirmLounge", simpleHandler(recruitable.confirmLounge))
	message.setHandler("recruit.confirmLoungeBehavior", simpleHandler(recruitable.confirmLoungeBehavior))
	message.setHandler("recruit.toggleFollow", simpleHandler(recruitable.handleToggleFollow))
	message.setHandler("recruit.relax", simpleHandler(recruitable.handleRelax))
	message.setHandler("recruit.holdPosition", simpleHandler(recruitable.handleHoldPosition))
	message.setHandler("recruit.lounge", simpleHandler(recruitable.handleLounge))
	message.setHandler("recruit.operate", simpleHandler(recruitable.handleOperate))
	message.setHandler("recruit.useSkill", simpleHandler(recruitable.handleUseSkill))
	message.setHandler("recruit.setTarget", simpleHandler(recruitable.handleSetTarget))
end

icCurrentStatus = {
	isHoldingPosition = false,
	isLounging = false,
	isOperating = false,
	isUsingSkill = false,
	targetPosition = nil,
	targetEntityId = nil
}

recruitable.attackTargetId = nil

icPreviousStatus = {}

function icSetStatus(status, args)
	status.isHoldingPosition = args.isHoldingPosition
	status.isLounging = args.isLounging
	status.isOperating = args.isOperating
	status.isUsingSkill = args.isUsingSkill
	status.targetPosition = args.targetPosition
	status.targetEntityId = args.targetEntityId
end

function recruitable.confirmFollow(skipNotification)
	recruitable.SetFollowLogic()
	icSetStatus(icCurrentStatus, { isHoldingPosition = false, isLounging = false, isOperating = false, isUsingSkill = false, targetPosition = nil, targetEntityId = nil })
	
	if not skipNotification then 
		recruitable.sendNotification("follow")
	end
end

function recruitable.confirmUnfollow(skipNotification)
	recruitable.SetUnfollowLogic()
	icSetStatus(icCurrentStatus, { isHoldingPosition = false, isLounging = false, isOperating = false, isUsingSkill = false, targetPosition = nil, targetEntityId = nil })
	
	if not skipNotification then
		recruitable.sendNotification("unfollow")
	end
end

function recruitable.confirmUnfollowBehavior(skipNotification)
	recruitable.SetUnfollowBehaviorLogic()
	icSetStatus(icCurrentStatus, { isHoldingPosition = false, isLounging = false, isOperating = false, isUsingSkill = false, targetPosition = nil, targetEntityId = nil })
	
	if not skipNotification then
		recruitable.sendNotification("unfollow")
	end
end

function recruitable.confirmHoldPosition(targetPosition, skipNotification)
	recruitable.SetUnfollowLogic()
	icSetStatus(icCurrentStatus, { isHoldingPosition = true, isLounging = false, isOperating = false, isUsingSkill = false, targetPosition = targetPosition, targetEntityId = nil })
	
	if not skipNotification then
		recruitable.sendNotification("holdPosition")
	end
end

function recruitable.confirmHoldPositionBehavior(targetPosition, skipNotification)
	recruitable.SetUnfollowBehaviorLogic()
	icSetStatus(icCurrentStatus, { isHoldingPosition = true, isLounging = false, isOperating = false, isUsingSkill = false, targetPosition = targetPosition, targetEntityId = nil })
	
	if not skipNotification then
		recruitable.sendNotification("holdPosition")
	end
end

function recruitable.confirmLounge(loungeableId, skipNotification)
	recruitable.SetUnfollowLogic()
	icSetStatus(icCurrentStatus, { isHoldingPosition = false, isLounging = true, isOperating = false, isUsingSkill = false, targetPosition = nil, targetEntityId = loungeableId })
	
	if not skipNotification then
		recruitable.sendNotification("lounge")
	end
end

function recruitable.confirmLoungeBehavior(loungeableId, skipNotification)
	recruitable.SetUnfollowBehaviorLogic()
	icSetStatus(icCurrentStatus, { isHoldingPosition = false, isLounging = true, isOperating = false, isUsingSkill = false, targetPosition = nil, targetEntityId = loungeableId })
	
	if not skipNotification then
		recruitable.sendNotification("lounge")
	end
end

function recruitable.SetFollowLogic()
	npc.setPersistent(false)
	npc.setKeepAlive(true)
	storage.followingOwner = true
	storage.behaviorFollowing = true
	
	if playerEntityId and world.entityExists(playerEntityId) then
		npc.setDamageTeam(recruitable.defaultDamageTeam)
	end
end

function recruitable.SetUnfollowLogic()
	npc.setPersistent(true)
	npc.setKeepAlive(false)
	storage.followingOwner = false
	storage.behaviorFollowing = false
	npc.setDamageTeam(recruitable.defaultDamageTeam)
end

function recruitable.SetUnfollowBehaviorLogic()
	npc.setPersistent(false)
	npc.setKeepAlive(true)
	storage.followingOwner = true
	storage.behaviorFollowing = false
	
	if playerEntityId and world.entityExists(playerEntityId) then
		npc.setDamageTeam(recruitable.defaultDamageTeam)
	end
end

function recruitable.handleToggleFollow()
	if storage.behaviorFollowing then
		if world.getProperty("ephemeral") then
			recruitable.confirmUnfollowBehavior()
		else
			world.sendEntityMessage(recruitable.ownerUuid(), "recruits.requestUnfollow", entity.uniqueId(), recruitable.recruitUuid())
		end
	else
		world.sendEntityMessage(recruitable.ownerUuid(), "recruits.requestFollow", entity.uniqueId(), recruitable.recruitUuid(), recruitable.generateRecruitInfo())
	end
end

function recruitable.handleRelax()
	if world.getProperty("ephemeral") then
		recruitable.confirmUnfollowBehavior()
	else
		world.sendEntityMessage(recruitable.ownerUuid(), "recruits.requestUnfollow", entity.uniqueId(), recruitable.recruitUuid())
	end
end

function recruitable.handleHoldPosition(args)
	local targetPosition = args.targetPosition
	
	if world.getProperty("ephemeral") then
		recruitable.confirmHoldPositionBehavior(targetPosition)
	else
		world.sendEntityMessage(recruitable.ownerUuid(), "recruits.requestHoldPosition", entity.uniqueId(), recruitable.recruitUuid(), targetPosition)
	end
end

function recruitable.handleLounge(args)
	local loungeableId = args.targetEntityId
	
	if world.getProperty("ephemeral") then
		recruitable.confirmLoungeBehavior(loungeableId)
	else
		world.sendEntityMessage(recruitable.ownerUuid(), "recruits.requestLounge", entity.uniqueId(), recruitable.recruitUuid(), loungeableId)
	end
end

function recruitable.handleOperate(args, skipNotification)
	local deviceId = args.targetEntityId
	
	icSetStatus(icPreviousStatus, icCurrentStatus)
	icSetStatus(icCurrentStatus, { isHoldingPosition = false, isLounging = false, isOperating = true, isUsingSkill = false, targetPosition = nil, targetEntityId = deviceId })
	
	if not skipNotification then
		recruitable.sendNotification("operate")
	end
end

function recruitable.handleUseSkill(args)
	icSetStatus(icCurrentStatus, { isHoldingPosition = false, isLounging = false, isOperating = false, isUsingSkill = true, targetPosition = nil, targetEntityId = nil })
end

function recruitable.handleSetTarget(args, skipNotification)
	if recruitable.attackTargetId == args.attackTargetId then
		recruitable.attackTargetId = nil
	else
		recruitable.attackTargetId = args.attackTargetId
	end
	
	if not skipNotification then
		recruitable.sendNotification("setTarget")
	end
end

function recruitable.operateDevice(deviceId)
	icSetStatus(icCurrentStatus, icPreviousStatus)
	world.callScriptedEntity(deviceId, "onInteraction")
end

function recruitable.isHoldingPosition()
	return icCurrentStatus.isHoldingPosition
end

function recruitable.isLounging()
	return icCurrentStatus.isLounging
end

function recruitable.isOperating()
	return icCurrentStatus.isOperating
end

function recruitable.isUsingSkill()
	return icCurrentStatus.isUsingSkill
end

function recruitable.stopUsingSkill()
	icSetStatus(icCurrentStatus, { isHoldingPosition = false, isLounging = false, isOperating = false, isUsingSkill = false, targetPosition = nil, targetEntityId = nil })
end

function recruitable.getTargetPosition()
	return icCurrentStatus.targetPosition
end

function recruitable.getTargetEntityId()
	return icCurrentStatus.targetEntityId
end

function recruitable.isAttackTargetSet()
	return recruitable.attackTargetId ~= nil
end

function recruitable.getAttackTargetId()
	return recruitable.attackTargetId
end

function recruitable.clearAttackTargetId()
	recruitable.attackTargetId = nil
end

function recruitable.sendNotification(message)
	local playerEntityId = world.loadUniqueEntity(recruitable.ownerUuid())
    notify( { type = message, sourceId = playerEntityId } )
end