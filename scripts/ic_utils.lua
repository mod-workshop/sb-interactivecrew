require "/scripts/staticrandom.lua"
--deepcopy, shallowOverwriteTable and toOverride are generic functions 
--borrowed from CrewCustomization+ util script.

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function shallowOverwriteTable(base, overwrites)
	if not overwrites then return base end
	if type(base) ~= "table" then return overwrites end
	for k,v in pairs(overwrites) do
		base[k] = v
	end
	return base
end


function toOverride(items)
	if not items then return nil end
	local override = {}
	for k,v in pairs(items) do
		override[k] = {v}
	end
	return override
end
