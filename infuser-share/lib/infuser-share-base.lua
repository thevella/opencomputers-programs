local component = require("component")
local os = require("os")
local infuser_share_base = {}

local debug = false

local transposers = {}

-- Check if string is empty
local function isempty(st)
    return st == nil or s == ''
end

-- Take a table and output its keys
local function printKeys(array)
    print("Keys :")
    for k, v in pairs(array) do
        print("  ", k, " : ", v)
    end
end

-- Load all the transposers into the table
-- for processing
local function loadTransposers()
    -- Reset transposers in case its already
    -- been used
    transposers = {}

    -- Loop through all transposers
    -- since they have to match the search string
    -- they can be just added.
    for address, componentType in component.list("transposer", false) do
        local transposer = {}

        -- Add the component as a proxy under "obj"
        transposer.obj = component.proxy(address)

        -- Output all of the transposer data
        if debug then
            print(componentType, " : ", transposer.obj.address)
        end

        -- Loop over all sides looking for inventories
        for i = 0, 5 do
            -- Get the sides inventory name
            local inv = transposer.obj.getInventoryName(i)

            -- Do nothing if the name is empty
            if not isempty(inv) then
                -- If the block is a mekanism machine, then
                -- It is saved as a machine block
                if "mekanism:machineblock" == inv then
                    transposer.machine = i
                    if debug then
                        print("machine : ", inv)
                    end

                -- If it is enderstorage, it is assumed to
                -- be input
                elseif string.find(inv, "enderstorage") then
                    transposer.in = i
                    if debug then
                        print("in : ", inv)
                    end

                -- If it is a valid inventory, but not any of
                -- the predefined ones, then it is extra out
                elseif not string.find(inv, "nil") then
                    transposer.extra = i
                    if debug then
                        print("extra : ", inv)
                    end

                end
            end
        end

        -- Add the transposer to the table
        table.insert(transposers, transposer)

        if debug then
            print("")
        end

    end
end

local inInventory(transposer, stackTest, inv)
    local stacks = transposer.obj.getAllStacks(inv)

    local stack = nil

    local next = next

    repeat
        stack = stacks()

        if stack then
            if next(stack) then
                if stack["name"] == stackTest["name"] and stack.size < stack.maxSize then
                    return true
                end
            else
                return true
            end
        end

        os.sleep(0)
    until (not stack)

    return false
end

-- Function to check if the required objects exist
local function hasExtraAndReg(transposer, extras, threshold)
    -- all of the stacks in the in inventory
    local stacks = transposer.obj.getAllStacks(transposer.in)

    -- The current stack, initialized in the loop
    local stack = nil

    -- where the extra and reg item stacks are
    local slots = {extra = nil, reg = nil, failed=false}

    -- The current slot, starts at 0, but is incremented
    -- inside the loop
    local slot = -1

    -- Store Stack size
    local sizes = {extra = 0, reg = 0}

    -- Store number of tries to put an item into
    -- the recieving inventory
    local tries = 0

    -- next function, here for speed
    local next = next

    -- While either hasReg or hasExtra is false
    -- Look for regular and extra items
    while (not slots.reg) or (not slots.extra) do
        if tries > threshold then
            slots.failed = true
            break
        end

        -- Next stack item
        stack = stacks()
        -- Increment the slot
        slot = slot + 1

        -- if the stack exists, and is not nil, and
        -- has items in it, procede
        if stack then
            if next(stack) then
                -- Print the keys in the array
                if debug then
                    printKeys(stack)
                end

                -- local variable to check if it has already
                -- been known to be an extra
                local isExtra = false

                -- Loop through valid extras
                for i = 1, #extras do
                    -- If the extra exists in the label, save the slot
                    if string.find(stack.label, extras[i]) then
                        -- If an extra has not already been found
                        if not slots.extra or sizes.extra < stack.size then
                            slots.extra = slot
                        end

                        isExtra = true
                        break
                    end
                end

                -- If its not an extra, and a reg has already not been found
                if not isExtra and (not slots.reg or sizes.reg < stack.size) and inInventory(transposer, stack, transposer.machine) then
                    slots.reg = slot
                end
            end
        else
            stacks = transposer.obj.getAllStacks(transposer.in)
            slot = -1
            slots.reg = nil
            slots.extra = nil
            sizes.reg = 0
            sizes.extra = 0
            tries = tries + 1

        end

        os.sleep(0)
    end

    return slots
end


function infuser_share_base.main(extras, debugChoice, threshold)
    debug = debugChoice

    local reSlot = true

    loadTransposers()
    
    local slots = nil
    while true do
        for try=1,threshold do
            for i=1,#transposers do
                if reSlot then
                    slots = hasExtraAndReg(transposers[i], extras, threshold)
                    reSlot = false
                end

                if slots.failed then
                    reslot = true

                else
                    print("success")
                end



                os.sleep(0)
            end
            os.sleep(0)
        end
        reSlot = true
    end
end

return infuser_share_base
--main({"Coal", "Carbon"}, true)
