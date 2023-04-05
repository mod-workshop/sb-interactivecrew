require "/scripts/companions/ic_recruitspawner.lua"

local base_init = init
local base_spawnCompanions = spawnCompanions
local prop_party = "ic_party"
local prop_partyChanged = "ic_partyChanged"
local spawnedCompanions = false;

local toggleFollowMessage = "recruit.toggleFollow"
local HoldPositionMessage = "recruit.holdPosition"
local loungeMessage = "recruit.lounge"
local operateMessage = "recruit.operate"
local useSkillMessage = "recruit.useSkill"
local setTargetMessage = "recruit.setTarget"

function init()
  base_init()
	message.setHandler("player.getIsOnShip", simpleHandler(handleGetIsOnShip))
	message.setHandler("player.getFollowerIds", simpleHandler(handleGetFollowerIds))
  message.setHandler("player.getPartyMembers", simpleHandler(handleGetPartyCrew))
	message.setHandler("player.getShipCrew", simpleHandler(handleGetShipCrew))
	message.setHandler("player.rebuildParty", simpleHandler(buildParty))
	message.setHandler("player.issueCrewCommand", simpleHandler(handleIssueCrewCommand))
	message.setHandler("recruits.requestJoinParty", simpleHandler(handleRequestJoinParty))
	message.setHandler("recruits.requestLeaveParty", simpleHandler(handleRequestLeaveParty))

  if not player.getProperty(prop_party) then
    player.setProperty(prop_party, {})
  end
end

function spawnCompanions()
  if not spawnedCompanions then
    spawnedCompanions = base_spawnCompanions()
  end

  if not spawnedCompanions then return false end
  local followerCount = recruitSpawner:followerCount()
  if followerCount == 0 then return true end
  local followers = playerCompanions.getCompanions("followers")
  if followerCount > 0 and followers[1].uniqueId == nil then return false end
  local partyOrder = player.getProperty(prop_party)

  if not partyOrder or partyOrder[1] == nil then
    buildParty()
  else
    refreshParty()
  end

  return true
end

function buildParty()
  sb.logInfo("ic.ic_player.buildParty > Building party list from scratch...")
  local followers = playerCompanions.getCompanions("followers")
  local partyOrder = {}

  for _, follower in ipairs(followers) do
    table.insert(partyOrder, {
      name = follower.config.parameters.identity.name,
      uniqueId = follower.uniqueId,
      podUuid = follower.podUuid
    })
  end

  player.setProperty(prop_party, partyOrder)
  player.setProperty(prop_partyChanged, true)
  sb.logInfo("ic.ic_player.buildParty > Party list:"..sb.print(player.getProperty(prop_party)))
end

function refreshParty()
  sb.logInfo("ic.ic_player.refreshParty > Refreshing party list...")
  local followers = playerCompanions.getCompanions("followers")
  local partyOrder = player.getProperty(prop_party)
  local newPartyOrder = {}

  for i, partyMember in ipairs(partyOrder) do
    for _, follower in ipairs(followers) do
      if partyMember.podUuid == follower.podUuid then
        table.insert(newPartyOrder, {
          name = follower.config.parameters.identity.name,
          uniqueId = follower.uniqueId,
          podUuid = follower.podUuid
        })
        break
      end
    end
  end

  if #newPartyOrder ~= #followers then
    buildParty()
    return
  end

  player.setProperty(prop_party, newPartyOrder)
  sb.logInfo("ic.ic_player.refreshParty > Party list:"..sb.print(player.getProperty(prop_party)))
end

function handleGetIsOnShip()
  return onOwnShip()
end

function handleGetFollowerIds()
  local party = player.getProperty(prop_party)
  local partyIds = {}

  for i, partyMember in ipairs(party) do
    table.insert(partyIds, partyMember.uniqueId)
  end

  return partyIds
end

function handleGetPartyCrew()
  return playerCompanions.getCompanions("followers")
end

function handleGetShipCrew()
  return playerCompanions.getCompanions("shipCrew")
end

function handleIssueCrewCommand(commandData)
  local followers = handleGetFollowerIds()
	local commandedFollower = followers[commandData.followerIndex]

  if commandedFollower ~= nil then
    local command = interpretCommand(commandedFollower, commandData.aimPosition)

    if command ~= "" then
      commandCrewmate(command)
    end
  end
end

function interpretCommand(followerId, position)
	local targetEntityId = world.entityQuery(position, 1.0, { includedTypes = { "creature" } })[1]

	if targetEntityId ~= nil then
	  local targetUniqueId = world.entityUniqueId(targetEntityId)

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
	world.sendEntityMessage(command.followerId, command.message, command.args)
end

function handleRequestJoinParty(uniqueId, recruitUuid)
  if onOwnShip() then
    promises:add(world.sendEntityMessage(uniqueId, "recruit.getRecruitInfo"), function(info)
      requestFollow(uniqueId, recruitUuid, info)
      end
    )
  end
end

function handleRequestLeaveParty(uniqueId, recruitUuid)
  if onOwnShip() then
    requestUnfollow(uniqueId, recruitUuid)
  end
end
