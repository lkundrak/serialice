-- SerialICE
--
-- Copyright (c) 2012 Kyösti Mälkki <kyosti.malkki@gmail.com>
-- Copyright (c) 2013 Alexandru Gagniuc <mr.nuke.me@gmail.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--


-- **********************************************************
--

function mainboard_io_read(f, action)

	-- IO slowdown
	if action.addr == 0xed then
		ignore_action(f, action)
		return drop_action(f, action, 0)
	end

	-- IO slowdown
	if action.addr == 0xeb then
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

	-- Catch RAM controller ready.
	if action.addr == 0x80 and action.data == 0x2c and not ram_enabled() then
		enable_ram()
	end

--	if action.addr == 0xcfb then
--		ignore_action(f, action)
--		return drop_action(f, action, 0)
--	end

	if action.addr == 0xeb then
		ignore_action(f, action)
		return drop_action(f, action, action.data)
	end

	if action.addr == 0xed then
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
	if action.addr == 0xeb or action.addr == 0xed then
		return true
	end

	-- If KBD controller returns status=0xff, clear 0x02.
	if action.addr == 0x64 and not action.write and action.size == 1  then
		if action.data == 0xff then
			-- tag these but give out correct data
			fake_action(f, action, action.data)
		end
	end
end

filter_mainboard = {
	name = "VIA",
	pre = mainboard_io_pre,
	post = mainboard_io_post,
	hide = hide_mainboard_io,
	base = 0x0,
	size = 0x10000
}

load_filter("via_bars")

function do_mainboard_setup()
	enable_hook(io_hooks, filter_pci_io_cfg)
	enable_hook(mem_hooks, filter_lapic)
	enable_hook(mem_hooks, filter_ioapic)

	enable_hook(cpumsr_hooks, filter_intel_microcode)
	enable_hook(cpuid_hooks, filter_multiprocessor)

	-- I have a hook to detect RAM initialisation from
	-- a POST code I can skip this here
	--enable_ram()

	enable_hook_pc80()
	enable_hook_superio(0x4e, 0x07)
	enable_hooks_vx900()

	-- Apply mainboard hooks last, so they are the first ones to check
	enable_hook(io_hooks, filter_mainboard)
end
