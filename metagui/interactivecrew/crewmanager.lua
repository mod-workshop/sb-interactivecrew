require "/scripts/ic_utils.lua"
require "/scripts/messageutil.lua"

local prop_party = "ic_party"
local prop_partyChanged = "ic_partyChanged"
local crew = { party = {}, ship = {} }
local selectedCrewName = nil
local selectedCrewUniqueId = nil
local selectedCrewWidget = nil


function init()
  player.setProperty(prop_partyChanged, false)

  --non-humanoid species handling for portraits.
  --Penguins borrowed from CrewCustomization+, might add others at some point.
  self.customSpecies = root.assetJson("/metagui/interactivecrew/customSpeciesRender.config:customSpecies")
 
  refreshParty()
  fillPartyList()
  refreshShipCrew()
  fillShipList()
end

function update()
  if player.getProperty(prop_partyChanged) then
    refreshParty()
    fillPartyList()
    refreshShipCrew()
    fillShipList()
    player.setProperty(prop_partyChanged, false)
  end
end

function refreshParty()
	local partyMembers = world.sendEntityMessage(player.id(), "player.getPartyMembers"):result()
  local party = {}

  for i, partyMember in ipairs(partyMembers) do
    party[partyMember.config.parameters.identity.name] = { data = partyMember }
  end

  crew.party = party
end

function refreshShipCrew()
	local shipCrewMembers = world.sendEntityMessage(player.id(), "player.getShipCrew"):result()
  local shipCrew = {}

  for i, shipCrewmate in ipairs(shipCrewMembers) do
    shipCrew[shipCrewmate.config.parameters.identity.name] = { data = shipCrewmate }
  end

  crew.ship = shipCrew
end

function fillPartyList()
  partyScrollArea:clearChildren()
  local partyOrder = player.getProperty(prop_party)

  if partyOrder then
    for i, partyMember in ipairs(partyOrder) do
      buildListItem(partyScrollArea, crew.party[partyMember.name], partyCrewSelected)
    end
  end
end

function fillShipList()
  shipScrollArea:clearChildren()
	local index = getIndexSortedByName(crew.ship, function(a, b) return a < b end)

	for _, name in pairs(index) do
    buildListItem(shipScrollArea, crew.ship[name], shipCrewSelected)
	end
end

function buildListItem(list, crewmate, onSelected)
  local name = crewmate.data.config.parameters.identity.name
	local species = crewmate.data.config.species
  local roleOverride = ((((crewmate.data.config.parameters.scriptConfig.personality.storedOverrides or {}).scriptConfig or {}).crew or {}).role or {}).name or ""
  role = crewmate.data.config.parameters.scriptConfig.crew.role or roleOverride
  local portrait = nil
	pcall(function()
		portrait = createPortrait(self.customSpecies[species] and self.customSpecies[species].mode or "bust", crewmate.data)
	end)
	
  if portrait then
    local listItem = list:addChild ({
      type = "listItem",
      data = { name = name, uniqueId = crewmate.data.uniqueId },
      size = { 143, 22 },
      expandMode = { 0, 0 }
    })
    local portraitPanel = listItem:addChild({
      type = "panel",
      size = { 20, 20 },
      expandMode = { 0, 0 }
    })
    local portraitSlot = portraitPanel:addChild({
      type = "canvas",
      size = { 16, 16 },
      expandMode = { 0, 0 },
      position = { 3, 2 }
    })
    local labelLayout = listItem:addChild({
      type = "layout",
      mode = "vertical",
      spacing = 1
    })
    portraitSlot.draw = drawPortrait
    portraitSlot:draw(portrait, species)
    labelLayout:addChild({ type = "label", text = name })
    labelLayout:addChild({ type = "label", text = "["..role.."]" })
    listItem.onSelected = onSelected
    crewmate.listItem = listItem
	else
		sb.logInfo("The species '"..species.."' is not currently installed. Crew member '"..(name or "unknown").."' won't be loaded.")
	end
end

function partyCrewSelected(item)
  if selectedCrewWidget then
    selectedCrewWidget:deselect()
  end

  selectedCrewWidget = item
  selectedCrewName = item.data.name
  selectedCrewUniqueId = item.data.uniqueId
  togglePartyControls(true)

  local onship = world.sendEntityMessage(player.id(), "player.getIsOnShip"):result()
  if onship then
    moveToParty:setVisible(false)
  end
end

function shipCrewSelected(item)
  if selectedCrewWidget then
    selectedCrewWidget:deselect()
  end

  selectedCrewWidget = item
  selectedCrewName = item.data.name
  selectedCrewUniqueId = item.data.uniqueId
  togglePartyControls(false)

  local onship = world.sendEntityMessage(player.id(), "player.getIsOnShip"):result()
  if onship then
    moveToParty:setVisible(true)
  end
end

function moveUpButton:onClick()
  local party = player.getProperty(prop_party)

  for i = 1, #party do
    if selectedCrewName == party[i].name then
      if i == 1 then return end
      party[i], party[i-1] = party[i-1], party[i]
      player.setProperty(prop_party, party)
      fillPartyList()
      crew.party[selectedCrewName].listItem:select()
      return
    end
  end
end

function moveDownButton:onClick()
  local party = player.getProperty(prop_party)

  for i, partyMember in ipairs(party) do
    if selectedCrewName == partyMember.name then
      if i == #party then return end
      party[i], party[i+1] = party[i+1], party[i]
      player.setProperty(prop_party, party)
      fillPartyList()
      crew.party[selectedCrewName].listItem:select()
      return
    end
  end
end

function moveToShip:onClick()
  togglePartyControls(false)
  moveToParty:setVisible(false)
	world.sendEntityMessage(
    player.id(),
    "recruits.requestLeaveParty",
    crew.party[selectedCrewName].data.uniqueId,
    crew.party[selectedCrewName].data.podUuid
  )
end

function moveToParty:onClick()
  togglePartyControls(false)
  moveToParty:setVisible(false)
	world.sendEntityMessage(
    player.id(),
    "recruits.requestJoinParty",
    crew.ship[selectedCrewName].data.uniqueId,
    crew.ship[selectedCrewName].data.podUuid
  )
end

function rebuildPartyData:onClick()
	world.sendEntityMessage(player.id(), "player.rebuildParty")
end

function togglePartyControls(isVisible)
  moveUpButton:setVisible(isVisible)
  moveDownButton:setVisible(isVisible)

  local onship = world.sendEntityMessage(player.id(), "player.getIsOnShip"):result()
  if onship then
    moveToShip:setVisible(isVisible)
  end
end

function createPortrait(mode, crewmate, itemSlots, customIdentity)
	local items = {}
	items.override = (itemSlots and toOverride(self.items or itemSlots)) or (crewmate.config.parameters.scriptConfig.initialStorage and toOverride(crewmate.config.parameters.scriptConfig.initialStorage.itemSlots)) or toOverride(crewmate.storage.itemSlots)
	items.override = items.override and {{0, {items.override}}} or nil
	local params  = {
		identity = shallowOverwriteTable(deepcopy(crewmate.config.parameters.identity), customIdentity),
		scriptConfig = crewmate.config.parameters.scriptConfig,
		items = items
	}

	local npcPort = root.npcPortrait(mode, crewmate.config.species, crewmate.config.type, 1, crewmate.config.seed, params)
	return npcPort
end

function drawPortrait(canvas, portrait, species)
  local c = widget.bindCanvas(canvas.backingWidget)
	local start = self.customSpecies[species] and self.customSpecies[species].offset or {-14,-18}
	for _,v in ipairs(portrait or {}) do
		c:drawImage(v.image,{v.position[1]+start[1], v.position[2]+start[2]}, 1, v.color, false)
	end
end

function getIndexSortedByName(tbl, sortFunction)
  local keys = {}
  for key in pairs(tbl) do
    table.insert(keys, key)
  end
  table.sort(keys, function(a, b)
    return sortFunction(tbl[a].data.config.parameters.identity.name, tbl[b].data.config.parameters.identity.name)
  end)
  return keys
end
