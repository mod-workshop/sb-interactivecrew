require "/scripts/messageutil.lua"

local base_recruitableInit = recruitable.init
local base_recruitableGenerateRecruitInfo = recruitable.generateRecruitInfo

function recruitable.init()
	base_recruitableInit()
	message.setHandler("recruit.getRecruitInfo", simpleHandler(recruitable.handleGetRecruitInfo))
	message.setHandler("recruit.toggleFollow", simpleHandler(recruitable.handleToggleFollow))
	message.setHandler("recruit.holdPosition", simpleHandler(recruitable.handleHoldPosition))
	message.setHandler("recruit.lounge", simpleHandler(recruitable.handleLounge))
	message.setHandler("recruit.operate", simpleHandler(recruitable.handleOperate))
	message.setHandler("recruit.useSkill", simpleHandler(recruitable.handleUseSkill))
	message.setHandler("recruit.setTarget", simpleHandler(recruitable.handleSetTarget))
end

function recruitable.generateRecruitInfo()
  local info = base_recruitableGenerateRecruitInfo()
  info.commandId = entity.uniqueId()
  info.config.parameters.scriptConfig.crew.role = config.getParameter("crew.role.name")
  return info
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

function recruitable.icFollow(skipNotification)
	recruitable.SetFollowLogic()
	icSetStatus(icCurrentStatus, { isHoldingPosition = false, isLounging = false, isOperating = false, isUsingSkill = false, targetPosition = nil, targetEntityId = nil })
	
	if not skipNotification then 
		recruitable.sendNotification("follow")
	end
end

function recruitable.icUnfollow(skipNotification)
	recruitable.SetUnfollowLogic()
	icSetStatus(icCurrentStatus, { isHoldingPosition = false, isLounging = false, isOperating = false, isUsingSkill = false, targetPosition = nil, targetEntityId = nil })
	
	if not skipNotification then
		recruitable.sendNotification("unfollow")
	end
end

function recruitable.icHoldPosition(targetPosition, skipNotification)
	recruitable.SetUnfollowLogic()
	icSetStatus(icCurrentStatus, { isHoldingPosition = true, isLounging = false, isOperating = false, isUsingSkill = false, targetPosition = targetPosition, targetEntityId = nil })
	
	if not skipNotification then
		recruitable.sendNotification("holdPosition")
	end
end

function recruitable.icLounge(loungeableId, skipNotification)
	recruitable.SetUnfollowLogic()
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
	npc.setPersistent(false)
	npc.setKeepAlive(true)
	storage.followingOwner = true
	storage.behaviorFollowing = false
	
	if playerEntityId and world.entityExists(playerEntityId) then
		npc.setDamageTeam(recruitable.defaultDamageTeam)
	end
end

function recruitable.handleGetRecruitInfo()
  return recruitable:generateRecruitInfo()
end

function recruitable.handleToggleFollow()
	if storage.behaviorFollowing then
      recruitable.icUnfollow(false)
	else
    recruitable.icFollow(false)
	end
end

function recruitable.handleHoldPosition(args)
	recruitable.icHoldPosition(args.targetPosition)
end

function recruitable.handleLounge(args)
	recruitable.icLounge(args.targetEntityId)
end

function recruitable.handleOperate(args, skipNotification)
	icSetStatus(icPreviousStatus, icCurrentStatus)
	icSetStatus(icCurrentStatus, { isHoldingPosition = false, isLounging = false, isOperating = true, isUsingSkill = false, targetPosition = nil, targetEntityId = args.targetEntityId })
	
	if not skipNotification then
		recruitable.sendNotification("operate")
	end
end

function recruitable.handleUseSkill()
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
