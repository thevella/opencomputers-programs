local fs = require("filesystem")
local shell = require("shell")

local args, options = shell.parse(...)
if #args < 2 then
	io.write("Usage:\n")
	io.write("  clone <from> <to>")
	return
end

local from = {
	fs = fs.proxy(args[1]),
	path = nil,
	label = nil
}
local to = {
	fs = fs.proxy(args[2]),
	path = nil,
	label = nil
}

from.label = from.fs.getLabel() == nil and from.fs.address or from.fs.getLabel()
to.label = to.fs.getLabel() == nil and to.fs.address or to.fs.getLabel()

if (from == nil or to == nil) then
	if (from == nil) then
		io.write(args[1] .. " is not valid.")
		return
	end

	io.write(args[2] .. " is not valid.")
	return
end

for file, path in fs.mounts() do
	if (file.address == from.fs.address) then
		from.path = path
	end

	if (file.address == to.fs.address) then
		to.path = path
	end
end

io.write("Copying files from " .. from.path .. " to " .. to.path .. ".\n")
shell.execute("cp -v -r " .. from.path .. "* " .. to.path)

io.write("Renaming " .. to.label .. " to \"Copy of " .. from.label .. "\".\n")
shell.execute("label " .. to.path .. " \"Copy of " .. from.label .. "\"\n")
