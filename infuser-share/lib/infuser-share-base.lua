local component = require("component")
local os = require("os")

local infuser_share_base = {}

local debug = false

local transposers = {}

-- Check if string is empty
local function isempty(st)
    return st == nil or st == ''
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
                if inv =="mekanism:machineblock" then
                    transposer.machine = i
                    if debug then
                        print("machine : ", inv)
                    end

                -- If it is enderstorage, it is assumed to
                -- be input
                elseif inv == "enderstorage:ender_storage" then
                    transposer.inv = i
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

local function machineInvCount(transposer)
    local stacks = transposer.obj.getAllStacks(transposer.machine)
    local stack = stacks()

    local counts = {empty = 0}


    local next = next
    -- Only loop over the stacks once
    repeat
        -- If the stack exists
        if stack then
            -- If the item is nil, it is empty and there
            -- is space, otherwise check other conditions
            if next(stack) then
                -- If the stack doesn not have an entry, add it
                -- otherwise, add new values to old
                if not counts[stack.name] or not next(counts[stack.name]) then
                    counts[stack.name] = {count = stack.size, space = stack.maxSize - stack.size}
                    if debug then
                        print("New Machine Stack : ")
                        print("  Name   : ", stack.name)
                        print("  Amount : ", stack.size)
                        print("")
                    end
                else
                    counts[stack.name].count = counts[stack.name].count + stack.size
                    counts[stack.name].space = counts[stack.name].space + (stack.maxSize - stack.size)
                    if debug then
                        print("Update Machine Stack : ")
                        print("  Name         : ", stack.name)
                        print("  Amount       : ", stack.size)
                        print("  Total Amount : ", counts[stack.name].count)
                        print("")
                    end
                end
            else
                counts.empty = counts.empty + 1
            end
        end

        -- Grab next stack
        stack = stacks()
    until (not stack)

    os.sleep(0)

    return counts

end

-- Function to check if the required objects exist
local function hasExtraAndReg(transposer, extras, threshold)
    -- all of the stacks in the in inventory
    local stacks = transposer.obj.getAllStacks(transposer.inv)
    -- The current stack, initialized in the loop
    local stack = nil

    local counts = machineInvCount(transposer)

    -- where the extra and reg item stacks are
    local slots = {extra = nil, reg = nil, failed=false, compressed=false}

    -- The current slot, starts at 1, but is incremented
    -- inside the loop
    local slot = 0

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
                    if stack.name == extras[i] then
                        -- If an extra has not already been found
                        if not slots.extra or sizes.extra < stack.size then
                            slots.extra = slot
                            sizes.extra = stack.size
                            slots.compressed = string.find(stack.name, "compressed")
                        end

                        isExtra = true
                        break
                    end
                end

                -- If its not an extra, and a reg has already not been found
                if not isExtra and (not slots.reg or sizes.reg < stack.size) then
                    if (counts[stack.name] and counts[stack.name].space > 0) or counts.empty > 0 then
                        slots.reg = slot
                        sizes.reg = stack.size
                    end
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
            stacks = transposer.obj.getAllStacks(transposer.inv)
            counts = machineInvCount(transposer)

            -- Reset slot to 1, but is incremented before next evaluation,
            -- it is set to 0
            slot = 0

            -- Reset slots to nil so we do not skip checking new
            slots.reg = nil
            slots.extra = nil

            -- Reset sizes of largest stack to 0
            sizes.reg = 0
            sizes.extra = 0

            -- increment tries
            tries = tries + 1

        end


    end
    os.sleep(0)

    if not slots.failed then
        -- If compressed, multiply the extra by 8 to get
        -- real size
        if slots.compressed then
            slots.min = math.min(sizes.reg, sizes.extra*8)
        else
            slots.min = math.min(sizes.reg, sizes.extra)
        end
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
                    print("  In      : ", transposers[i].inv)
                    print("  Extras  : ", transposers[i].extra)
                    print("")
                end

                -- Only reslot when needed
                if reSlot or not transposers[i].obj.getStackInSlot(transposers[i].inv, slots.reg) or not transposers[i].obj.getStackInSlot(transposers[i].inv, slots.extra) then
                    slots = hasExtraAndReg(transposers[i], extras, threshold)
                    if debug then
                        print("\nSlots : ")
                        print("  Reg   : ", slots.reg)
                        print("  Extra : ", slots.extra)
                        print("")
                    end

                    reSlot = false
                end

                -- If it failed, reslot
                if not slots.failed then
                    if debug then
                        print("transfering : ")
                    end

                    local transfered = transposers[i].obj.transferItem(transposers[i].inv, transposers[i].machine, slots.min, slots.reg)
                    if transfered then
                        -- If its compressed, move only as many
                        -- items as 1/8 th as many of regular
                        if slots.compressed then
                            transfered = math.ceil(transfered/8)
                        end
                        transposers[i].obj.transferItem(transposers[i].inv, transposers[i].extra, transfered, slots.extra)
                    end

                    if transfered == slots.min then
                        reSlot = true
                    end
                else
                    reSlot = true
                end
            end
            os.sleep(0)
        end

        reSlot = true

    end
end

return infuser_share_base
--main({"Coal", "Carbon"}, true)
