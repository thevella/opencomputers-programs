local infuser_share_base = require("infuser-share-base")
local debug = false

local next = next
if arg and next(arg) then
    if arg[1] == "--debug" then
        debug = true
    end
end

infuser_share_base.main({"Coal", "Carbon"}, false)
