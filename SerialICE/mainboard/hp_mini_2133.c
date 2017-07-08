/*
 * This file is part of the SerialICE project.
 *
 * Copyright (C) 2017	Lubomir Rintel <lkundrak@v3.sk>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

const char boardname[33] = "HP Mini 2133                    ";

static void chipset_init(void)
{
	/* Disable the watchdog. */
	outb (0x30, 0x500);
	outb (0xaa, 0x501);
}
