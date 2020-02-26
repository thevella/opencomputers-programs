local infuser_share_base = require("infuser-share-base")
local shell = require("shell")

local debug = false

local args, options = shell.parse(...)

local next = next
if args and next(args) then
    debug = args[1] == "debug"
end

infuser_share_base.main({"Coal", "Carbon"}, debug)
