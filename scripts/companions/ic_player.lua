require "/scripts/companions/ic_recruitspawner.lua"

local base_init = init
local base_spawnCompanions = spawnCompanions
local prop_party = "ic_party"
local prop_partyChanged = "ic_partyChanged"
local spawnedCompanions = false;

function init()
	base_init()
	message.setHandler("player.getIsOnShip", simpleHandler(handleGetIsOnShip))
	message.setHandler("player.getFollowerIds", simpleHandler(handleGetFollowerIds))
	message.setHandler("player.getPartyMembers", simpleHandler(handleGetPartyCrew))
	message.setHandler("player.getShipCrew", simpleHandler(handleGetShipCrew))
	message.setHandler("player.rebuildParty", simpleHandler(handleBuildParty))
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
    handleBuildParty()
  else
    refreshParty()
  end

  return true
end

function handleBuildParty()
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
end

function refreshParty()
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
    handleBuildParty()
    return
  end

  player.setProperty(prop_party, newPartyOrder)
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
