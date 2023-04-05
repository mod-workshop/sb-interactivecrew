require "/scripts/ic/keybinds.lua"
require "/scripts/ic/keybinds_scriptHooks.lua"

hook("init", function()
   Bind.create("shift=false specialThree", commandFollower1, false, false)
   Bind.create("shift specialThree", commandFollower2, false, false)
end)

function commandFollower1()
  local commandData = { followerIndex = 1, aimPosition = tech.aimPosition() } 
  world.sendEntityMessage(entity.id(),"player.issueCrewCommand", commandData)
end

function commandFollower2()
  local commandData = { followerIndex = 2, aimPosition = tech.aimPosition() } 
  world.sendEntityMessage(entity.id(),"player.issueCrewCommand", commandData)
end
