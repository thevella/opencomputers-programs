local infuser_share_base = require("infuser-share-base")
local shell = require("shell")

local debug = false

local args, options = shell.parse(...)

local threshold = 2

local next = next

if args and next(args) then
    for i=1,#args then
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

if options and next(options) then
    for k,v in options then

    end
end

infuser_share_base.main({"Coal", "Carbon"}, debug, threshold)
