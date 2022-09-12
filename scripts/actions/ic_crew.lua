require "/scripts/companions/ic_recruitable.lua"

function isHoldingPosition(args, board)
	local targetPosition = recruitable.getTargetPosition()
	
	if recruitable.isHoldingPosition() then
		return true, { targetPosition = targetPosition }
	else
		return false
	end
end

function isLounging(args, board)
	return recruitable.isLounging()
end

function isOperating(args, board)
	return recruitable.isOperating()
end

function isUsingSkill(args, board)
	return recruitable.isUsingSkill()
end

function stopUsingSkill(args, board)
	recruitable.stopUsingSkill()
	return true
end

function isAttackTargetSet(args, board)
	return recruitable.isAttackTargetSet()
end

function getAttackTarget(args, board)
	local attackTargetId = recruitable.getAttackTargetId()
	
	if entity.isValidTarget(attackTargetId) then
		return true, { target = attackTargetId }
	else
		recruitable.clearAttackTargetId()
		return false
	end
end

function getTargetEntityId(args, board)
	local targetEntityId = recruitable.getTargetEntityId()
	
	if targetEntityId ~= nil then
		return true, { targetEntityId = targetEntityId }
	else
		return false
	end
end

function operateDevice(args, board)
	recruitable.operateDevice(args.deviceId)
	return true
end

function icLogValue(args, board)
	sb.logInfo("Logging value as: "..sb.print(args.valueToLog))
	return true
end