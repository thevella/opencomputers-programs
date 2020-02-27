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

-- Check if the item can be added to the inventory
local inInventory(transposer, stackTest, inv)
    local stacks = transposer.obj.getAllStacks(inv)
    local stack = nil


    local next = next
    -- Only loop over the stacks once, if not there
    -- Fail
    repeat
        -- Grab next stack
        stack = stacks()

        -- If the stack exists
        if stack then
            -- If the item is nil, it is empty and there
            -- is space, otherwise check other conditions
            if next(stack) then
                -- If the stack has the same name and the size is less
                -- than the max stack size, there is space. Return true
                if stack["name"] == stackTest["name"] and stack.size < stack.maxSize then
                    return true
                end
            else
                return true
            end
        end
        os.sleep(0)
    until (not stack)

    -- If the stack wasn't in inventory, return false
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
        -- If the stack was nil, we reached the end of the
        -- stacks
        else
            -- If tries is greater than set threshold,
            -- break and return failed
            if tries >= threshold then
                slots.failed = true
                break
            end

            -- Grab new stacks object
            stacks = transposer.obj.getAllStacks(transposer.in)

            -- Reset slot to 0, but is incremented before next evaluation,
            -- it is set to -1
            slot = -1

            -- Reset slots to nil so we do not skip checking new
            slots.reg = nil
            slots.extra = nil

            -- Reset sizes of largest stack to 0
            sizes.reg = 0
            sizes.extra = 0

            -- increment tries
            tries = tries + 1

        end

        os.sleep(0)
    end

    -- Return placements of the slots, and whether it failed
    return slots
end


function infuser_share_base.main(extras, debugChoice, threshold)
    -- Grab debug from call
    debug = debugChoice

    -- Whether to check for the existence of
    -- new stacks
    local reSlot = true

    -- Load all of the transposers and their
    -- side values
    loadTransposers()

    local next = next

    -- Quit if no transposer are found
    if not next(transposers) then
        print("\n\nFailure!")
        print("  No transposers detected on network!\n\n")
        os.exit()
    end

    local slots = nil


    while true do
        -- Loop as many as the threshold
        for try=1,threshold do
            -- Loop through all transposers
            for i=1,#transposers do
                if debug then
                    print("Transposer : ", i)
                    print("  Address : ", transposers[i].obj.address)
                    print("  Machine : ", transposers[i].machine)
                    print("  In      : ", transposers[i].in)
                    print("  Extras  : ", transposers[i].extra)
                    print("")
                end

                -- Only reslot when needed
                if reSlot then
                    slots = hasExtraAndReg(transposers[i], extras, threshold)
                    reSlot = false
                end

                -- If it failed, reslot
                if not slots.failed then
                    print("success")
                else
                    reslot = true
                end

                os.sleep(0)
            end
            os.sleep(0)
        end
        -- Reslot if reached threshold
        reSlot = true
    end
end

return infuser_share_base
--main({"Coal", "Carbon"}, true)
