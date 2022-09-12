local base_recruitSpawnerClearDirty = recruitSpawner.clearDirty
local base_recruitSpawnerRecruitFollowing = recruitSpawner.recruitFollowing
local base_recruitSpawnerRecruitUnfollowing = recruitSpawner.recruitUnfollowing
local prop_party = "ic_party"
local prop_partyChanged = "ic_partyChanged"

function recruitSpawner.clearDirty(rspawner)
  base_recruitSpawnerClearDirty(rspawner)
  player.setProperty(prop_partyChanged, true)
end

function recruitSpawner.recruitFollowing(rspawner, onShip, recruitUuid, recruitInfo)
  base_recruitSpawnerRecruitFollowing(rspawner, onShip, recruitUuid, recruitInfo)

  if onShip then
    addCrewToParty(recruitUuid, recruitInfo.commandId, recruitInfo.name)
  end
end

function recruitSpawner.recruitUnfollowing(rspawner, onShip, recruitUuid)
  base_recruitSpawnerRecruitUnfollowing(rspawner, onShip, recruitUuid)

  if onShip then
    removeFollowerFromParty(recruitUuid)
  end
end

function addCrewToParty(podUuid, uniqueId, name)
  local partyOrder = player.getProperty(prop_party)
  local newPartyMember = { name = name, uniqueId = uniqueId, podUuid = podUuid }
  local newPartyOrder = {}

  if #partyOrder == 0 then
    table.insert(newPartyOrder, newPartyMember)
    player.setProperty(prop_party, newPartyOrder)
    return
  end

  local foundIt = false

  for i, partyMember in ipairs(partyOrder) do
    table.insert(newPartyOrder, {
      name = partyMember.name,
      uniqueId = partyMember.uniqueId,
      podUuid = partyMember.podUuid
    })
    if podUuid == partyMember.podUuid then
      foundIt = true
    end
  end

  if not foundIt then
    table.insert(newPartyOrder, newPartyMember)
  end

  player.setProperty(prop_party, newPartyOrder)
end

function removeFollowerFromParty(podUuid)
  local partyOrder = player.getProperty(prop_party)
  local newPartyOrder = {}

  for i, partyMember in ipairs(partyOrder) do
    if podUuid == partyMember.podUuid then goto continue end
    table.insert(newPartyOrder, {
      name = partyMember.name,
      uniqueId = partyMember.uniqueId,
      podUuid = partyMember.podUuid
    })
    ::continue::
  end
 
  player.setProperty(prop_party, newPartyOrder)
end
