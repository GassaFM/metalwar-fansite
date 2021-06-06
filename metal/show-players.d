// Author: Ivan Kazmenko (gassa@mail.ru)
module show_players;
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

char [] toCommaNumber (long value)
{
	int pos = 24;
	auto res = new char [pos];
	do
	{
		pos -= 1;
		if (!(pos & 3))
		{
			res[pos] = ',';
			pos -= 1;
		}
		res[pos] = cast (char) (value % 10 + '0');
		value /= 10;
	}
	while (value != 0);
	return res[pos..$];
}

struct PlayerInfo
{
	string name;
	int [string] amount;
	int points;
}

int main (string [] args)
{
	auto nowTime = Clock.currTime (UTC ());

	string [] unitTypes;
	int [string] pointsByType;

	auto addUnitType (string name, int points)
	{
		unitTypes ~= name;
		pointsByType[name] = points;
	}

	addUnitType ("Wolf",        1);
	addUnitType ("Ant",         2);
	addUnitType ("Skunk",       4);
	addUnitType ("Raccoon",     8);
	addUnitType ("Elephantor", 16);
	addUnitType ("Hamster",    16);

	PlayerInfo [string] playersTable;
	PlayerInfo totals;
	totals.name = "Total:";

	auto unitsTable = File ("units.binary", "rb")
	    .byLineCopy.join ('\n').parseJSON;

	foreach (line; unitsTable["rows"].array)
	{
		auto buf = line["hex"].str.hexStringToBinary;
		auto unit = buf.parseBinary !(unitsElement);
		assert (buf.empty);

		auto playerName = unit.owner.text;
		auto unitType = unit.name;

		if (playerName !in playersTable)
		{
			playersTable[playerName] = PlayerInfo (playerName);
		}
		playersTable[playerName].amount[unitType] += 1;
		totals.amount[unitType] += 1;

		playersTable[playerName].points += pointsByType[unitType];
		totals.points += pointsByType[unitType];
	}

	auto players = playersTable.byValue.array;
	auto playersIndex = players.length.iota.array;
	playersIndex.schwartzSort !(z =>
	    tuple (-players[z].points, players[z].name));

	auto nowString = nowTime.toISOExtString[0..19];
	auto nowUnix = nowTime.toUnixTime ();

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
		auto name = "metal";
		auto file = File (name ~ "-players.html", "wt");
		writeHeader (file, "Metal War Players");

		file.writeln (`<p>Click on a column header ` ~
		    `to sort.</p>`);
		file.writeln (`<p height="5px"></p>`);
		file.writeln (`<table class="log" ` ~
		    `id="players-table">`);
		file.writeln (`<thead>`);
		file.writeln (`<tr>`);
		file.writefln !(`<th>#</th>`);
		file.writefln !(`<th class="header" ` ~
		    `id="col-player">Player</th>`);
		foreach (line; unitTypes)
		{
			file.writefln !(`<th width=10%% class="header" ` ~
			    `id="col-%s">%s</th>`) (line.toLower, line);
		}
		file.writefln !(`<th class="header" ` ~
		    `id="col-points">Points</th>`);
		file.writefln !(`<th id="col-percent">Share</th>`);

		auto writePlayer (long i, ref PlayerInfo player)
		{
			file.writefln !(`<tr>`);
			file.writefln !(`<td class="amount">%s</td>`)
			    ((i >= 0) ? text (i + 1) : "&nbsp;");
			file.writefln !(`<td class="name">%s</td>`)
			    (player.name);
			foreach (line; unitTypes)
			{
				file.writefln !(`<td class="amount">%s</td>`)
				    (player.amount.get (line, 0)
				    .toCommaNumber);
			}
			file.writefln !(`<td class="amount">%s</td>`)
			    (player.points.toCommaNumber);
			file.writefln !(`<td class="amount">%s</td>`)
			    ((i >= 0) ? format !(`%.02f%%`)
			    (player.points * 100.0 / totals.points) :
			    "&nbsp;");
			file.writefln !(`</tr>`);
		}

		writePlayer (-1, totals);
		file.writefln !(`<tr height=5px></tr>`);
		file.writeln (`</thead>`);
		file.writeln (`<tbody>`);
		foreach (i, j; playersIndex)
		{
			writePlayer (cast (long) (i), players[j]);
		}
		file.writeln (`</tbody>`);
		file.writeln (`<tfoot>`);
		file.writefln !(`<tr height=5px></tr>`);
		writePlayer (-1, totals);
		file.writeln (`</tfoot>`);

		file.writeln (`</table>`);
		file.writefln (`<script type="text/javascript" ` ~
		    `src="sort-players.js"></script>`);
		writeFooter (file);
	}

	return 0;
}
