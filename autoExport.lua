local component = require("component")
local internet = component.internet
local export, import = component.proxy("704a7839-255b-4c13-8749-048a8ce36a55"), component.proxy("c79ff597-8e8c-467a-a863-8983fc8a72ae")
local importSide = "SOUTH"
local items, oldSlot

if not export then
	error("Need export!")
end
if not import then
	error("Need import")
end

local function request(path)
    local handle, data, chunk = internet.request(path), ""

    while true do
        chunk = handle.read(math.huge)

        if chunk then
            data = data .. chunk
        else
            break
        end
    end
     
    handle.close()
    return data
end

local function getAllItemCount(fingerprints, needed, cmp)
    local allCount, availableItems = 0, {}

    for i = 1, #fingerprints do
        local checkItem = cmp.getItemDetail(fingerprints[i])

        if checkItem then
        	local count = checkItem.basic().qty

            if needed and (count >= needed) then
                table.insert(availableItems, {fingerprint = fingerprints[i], count = needed})
                allCount = needed
                break
            end

            if needed and (count + allCount > needed) then
                table.insert(availableItems, {fingerprint = fingerprints[i], count = count - allCount})
                allCount = allCount + (count - allCount)
                break
            else
                table.insert(availableItems, {fingerprint = fingerprints[i], count = count})
                allCount = allCount + count
            end
        end
    end

    return allCount, availableItems
end

local function insert(fingerprint, count)
    local checkItem = export.getItemDetail(fingerprint)

    if checkItem then
        local item = checkItem.basic()

        if item.qty >= count then
            if count > item.max_size then
                for stack = 1, math.ceil(count / item.max_size) do
                    local stack = count > item.max_size
                    repeat
                        success = export.exportItem(fingerprint, importSide, stack and item.max_size or count, 1)
                    until success.size >= 1
                    count = stack and count - item.max_size or count
                end
            else
            	local success

            	repeat
            		success = export.exportItem(fingerprint, importSide, count, 1)
            	until success.size >= 1
            end
        end
    end
end

local data = request("https://raw.githubusercontent.com/ILIa3174/market/master/items.lua")
local chunk, err = load("return " .. data, "=items.lua", "t")
if not chunk then 
    error("?????????????????????? ?????????????????????????????? ???????? ??????????! " .. err)
else
    items = chunk()
end

while true do 
    for item = 1, #items.shop do 
    	if items.shop[item].needed and import.getItemDetail({dmg=0.0,id="minecraft:wooden_hoe"}) then
    		print("Scanning " .. items.shop[item].text .. "...")
    		local importCount = getAllItemCount(items.shop[item].fingerprint, false, import)

    		if importCount < items.shop[item].needed then
    			local needed = items.shop[item].needed - importCount
    			local exportCount, fingerprints = getAllItemCount(items.shop[item].fingerprint, needed, export)
                local allExportCount = getAllItemCount(items.shop[item].fingerprint, false, export)

    			if items.shop[item].buffer and (allExportCount - needed) >= items.shop[item].buffer or not items.shop[item].buffer then
    				print("Need item (import - " .. needed .. ") - index " .. items.shop[item].text .. ", exporting...")

    				for i = 1, #fingerprints do 
    					pcall(insert, fingerprints[i].fingerprint, fingerprints[i].count)
    				end
    			else
    				print("Need item (export) - index " .. items.shop[item].text .. "...")
    			end
    		end
    	end
    	os.sleep(0)
    end
end