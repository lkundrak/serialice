-- SerialICE
--
-- Copyright (c) 2012 Kyösti Mälkki <kyosti.malkki@gmail.com>
-- Copyright (c) 2013 Alexandru Gagniuc <mr.nuke.me@gmail.com>
-- Copyright (c) 2017 Lubomir Rintel <lkundrak@v3.sk>
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

-- HP Mini 2133 support.
--
-- The machine doesn't have a UART, however it has LPC pins routed to the
-- PCI Express Mini Card slot originally occupied by the Broadcom WLAN
-- adapter.
--
-- I've used a cheapo LPC POST card's pin header as a breakout and
-- connected a CPLD (on an Altera EPM240T100 evaluation board) with simple
-- UART emulator you can find at <https://github.com/lkundrak/lpc-uart>

function mainboard_io_pre(f, action)
	-- Catch RAM controller ready.
	if action.write and action.addr == 0x80 and action.data == 0xe9 and not ram_enabled() then
		enable_ram()
		return false
	end

	-- IO slowdown
	if action.addr >= 0xea and action.addr <= 0xef then
		ignore_action(f, action)
		drop_action(f, action, action.data)
		return true
	end

	return false
end

function mainboard_io_post(f, action)
	if action.addr >= 0xea and action.addr <= 0xef then
		return true
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

function speedstep_pre(f, action)
	-- When the factory BIOS sets IA32_PERF_CONTROL to 0x0810 (8x speed
	-- with 0.956V core voltage), the board hangs soon after the first
	-- write of NOP to DRAM. Not sure why that happens, perhaps related
	-- to us doing the serial I/O at the time, but skipping it lets us
	-- finish raminit happily.
	if action.write and action.rin.ecx == 0x199 then
		drop_action(f, action)
		return true
	end

	return false
end

filter_speedstep = {
	name = "Enhanced SpeedStep",
	pre = speedstep_pre,
	post = speedstep_post,
}

function do_mainboard_setup()
	do_default_setup()

	-- Well, this is vn896, but close enough...
	enable_hooks_vx900()

	new_car_region(0xffef0000, 0x8000)

	enable_hook(cpumsr_hooks, filter_speedstep)

	-- Apply mainboard hooks last, so they are the first ones to check
	enable_hook(io_hooks, filter_mainboard)
end
