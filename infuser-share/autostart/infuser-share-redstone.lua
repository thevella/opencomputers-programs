local infuser_share_base = require("infuser-share-base")


function start()
    local thread = require("thread")
    local debug = false

    local threshold = 2

    local next = next

    if args and next(args) then
        for i=1,#args do
            if args[i] == "debug" then
                debug = true
            elseif string.find(args[i], "threshold=") then
                local temp = tonumber(string.sub(args[i], string.find(args[i], "=")+1, #args[i]))

                if temp and temp > 0 then
                    threshold = math.ceil(temp)
                end
            end
            os.sleep(0)
        end
    end

    thread.create(infuser_share_base.main({"minecraft:redstone", "mekanism:compressedredstone"}, debug, threshold)):detach()
end
