-- param entity
inspectEntity = function(args, board)
  if not args.entity or not world.entityExists(args.entity) then return false end

  local options = {}
  local species = nil
  if entity.entityType() == "npc" then
    species = npc.species()
    options.sound = randomChatSound()
  end
  
  if world.entityDescription(args.entity, species) == world.entityDescription(args.entity) then
    species = "human"
  end
  
  local dialog = world.entityDescription(args.entity, species)
  if not dialog then return false end

  context().say(dialog, {}, options)
  return true
end
