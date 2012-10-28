


function mainboard_io_read(f, action)
	-- Some timer loop
	if ( action.addr == 0x61 ) then
		if ( regs.eip == 0x1634 ) then
			regs.ecx = 0x01
			return fake_action(f, action, 0x20)
		end
		if ( regs.eip == 0x163a ) then
			regs.ecx = 0x01
			return fake_action(f, action, 0x30)
		end
	end

	-- IO slowdown
	if action.addr == 0xed then
		ignore_action(f, action)
		return drop_action(f, action, 0)
	end

	if action.addr == 0xcfb then
		ignore_action(f, action)
		return drop_action(f, action, 0)
	end

	return skip_filter(f, action)
end


function mainboard_io_write(f, action)


	if action.addr == 0xcfb then
		ignore_action(f, action)
		return drop_action(f, action, 0)
	end

	if action.addr == 0xe1 then
		ignore_action(f, action)
		return drop_action(f, action, action.data)
	end

	return skip_filter(f, action)
end

function mainboard_io_pre(f, action)
	if action.write then
		return mainboard_io_write(f, action)
	else
		return mainboard_io_read(f, action)
	end
end

function mainboard_io_post(f, action)
	if action.addr == 0xe1 or action.addr == 0xed or action.addr == 0xcfb then
		return true
	end
	if action.addr == 0x80 and not action.write then
		return true
	end
end

filter_mainboard = {
	id = -1,
	name = "test",
	pre = mainboard_io_pre,
	post = mainboard_io_post,
	hide = hide_mainboard_io,
	base = 0x0,
	size = 0x10000
}

dofile("i82801.lua")
dofile("intel_bars.lua")

function do_mainboard_setup()
	do_default_setup()

	enable_hook_i82801gx()

	northbridge_i945()

	-- Apply mainboard hooks last, so they are the first ones to check
	enable_hook(io_hooks, filter_mainboard)
end
