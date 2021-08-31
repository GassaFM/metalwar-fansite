// Author: Ivan Kazmenko (gassa@mail.ru)
module show_active;
import std.algorithm;
import std.ascii;
import std.conv;
import std.datetime;
import std.format;
import std.json;
import std.math;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

import metalwargame_abi;
import transaction;
import utilities;

void main (string [] args)
{
	auto nowTime = Clock.currTime (UTC ());
	auto nowString = nowTime.toISOExtString[0..19];
	auto nowUnix = nowTime.toUnixTime ();

	auto teleportsTable = File ("teleports.binary", "rb")
	    .byLineCopy.join ('\n').parseJSON;
	bool [long] teleports;
	long [] teleportsList;
	foreach (line; teleportsTable["rows"].array)
	{
		auto buf = line["hex"].str.hexStringToBinary;
		auto teleport = buf.parseBinary !(teleportsElement);
		assert (buf.empty);

		teleportsList ~= teleport.location;
		teleports[teleport.location] = true;
	}

	auto unitsTable = File ("units.binary", "rb")
	    .byLineCopy.join ('\n').parseJSON;

	int [2] [ulong] baseTotal;
	foreach (loc; teleportsList)
	{
		baseTotal[loc] = [0, 0];
	}

	void writeHeader (ref File file, string title)
	{
		file.writeln (`<!DOCTYPE html>`);
		file.writeln (`<html xmlns=` ~
		    `"http://www.w3.org/1999/xhtml">`);
		file.writeln (`<meta http-equiv="content-type" ` ~
		    `content="text/html; charset=UTF-8">`);
		file.writeln (`<head>`);
		file.writefln (`<title>%s</title>`, title);
		file.writeln (`<link rel="stylesheet" ` ~
		    `href="./log.css" type="text/css">`);
		file.writeln (`</head>`);
		file.writeln (`<body>`);
		file.writefln (`<p><a href="./index.html">` ~
		    `Back to main page</a></p>`);
		file.writefln (`<h2>%s:</h2>`, title);
	}

	void writeFooter (ref File file)
	{
		file.writefln (`<p>Generated on %s (UTC).</p>`,
		    nowString);
		file.writefln (`<p><a href="./index.html">` ~
		    `Back to main page</a></p>`);
		file.writeln (`</body>`);
		file.writeln (`</html>`);
	}

	{
		auto tableName = "units";
		auto file = File (tableName ~ "-on-map.html", "wt");
		writeHeader (file, "Metal War Units on Map");

		file.writeln (`<table class="log" ` ~
		    `id="units-table">`);
		file.writeln (`<thead>`);
		file.writeln (`<tr>`);
		file.writefln !(`<th>#</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-id">ID</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-owner">Owner</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-x">X</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-y">Y</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-name">Name</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-health">Health</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-cargo">Cargo</th>`);
		file.writeln (`</thead>`);
		file.writeln (`<tbody>`);

		int num = 0;
		foreach (line; unitsTable["rows"].array)
		{
			auto buf = line["hex"].str.hexStringToBinary;
			auto unit = buf.parseBinary !(unitsElement);
			assert (buf.empty);

			if (unit.location in teleports)
			{
				baseTotal[unit.location]
				    [unit.type == "miner"] += 1;
				continue;
			}
			num += 1;

			auto owner = unit.owner.text;
			auto name = unit.name;
			auto id = unit.asset_id;
			auto curX = unit.location / 100_000;
			auto curY = unit.location % 100_000;

			file.writefln !(`<tr>`);
			file.writefln !(`<td class="amount">%s</td>`) (num);
			file.writefln !(`<td class="amount">%s</td>`) (id);
			file.writefln !(`<td class="name">%s</td>`) (owner);
			file.writefln !(`<td class="amount">%s</td>`) (curX);
			file.writefln !(`<td class="amount">%s</td>`) (curY);
			file.writefln !(`<td class="name">%s</td>`) (name);
			file.writefln !(`<td class="amount">%s</td>`)
			    (unit.hp.text ~ "/" ~ unit.strength.text);
			file.writefln !(`<td class="amount">%s</td>`)
			    (unit.stuff.map !(item =>
			    item.amount * item.weight).sum (0).text ~ "/" ~
			    text (unit.capacity * 10));
			file.writefln !(`</tr>`);
		}

		file.writeln (`</tbody>`);
		file.writeln (`</table>`);

		file.writefln !(`<script type="text/javascript" ` ~
		    `src="sort-units.js"></script>`);
		writeFooter (file);
	}

	{
		auto tableName = "garages";
		auto file = File (tableName ~ ".html", "wt");
		writeHeader (file, "Metal War Garages");

		file.writeln (`<table class="log" ` ~
		    `id="units-table">`);
		file.writeln (`<thead>`);
		file.writeln (`<tr>`);
		file.writefln !(`<th>#</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-x">X</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-y">Y</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-fighters">Fighters</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-miners">Miners</th>`);
		file.writeln (`</thead>`);
		file.writeln (`<tbody>`);

		int num = 0;
		foreach (loc; teleportsList)
		{
			num += 1;

			auto curX = loc / 100_000;
			auto curY = loc % 100_000;

			file.writefln !(`<tr>`);
			file.writefln !(`<td class="amount">%s</td>`) (num);
			file.writefln !(`<td class="amount">%s</td>`) (curX);
			file.writefln !(`<td class="amount">%s</td>`) (curY);
			file.writefln !(`<td class="amount">%s</td>`)
			    (baseTotal[loc][0]);
			file.writefln !(`<td class="amount">%s</td>`)
			    (baseTotal[loc][1]);
			file.writefln !(`</tr>`);
		}

		file.writeln (`</tbody>`);
		file.writeln (`</table>`);

		writeFooter (file);
	}
}
