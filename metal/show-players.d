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

immutable int hamsterMetalGain = 100;

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
	int [string] healthByType;
	int [string] pointsByType;

	auto addUnitType (string name, int health, int points)
	{
		unitTypes ~= name;
		healthByType[name] = health;
		pointsByType[name] = points;
	}

	addUnitType ("Wolf",       250, 1);
	addUnitType ("Ant",        400, 2);
	addUnitType ("Skunk",      400, 4);
	addUnitType ("Raccoon",    600, 8);
	addUnitType ("Elephantor", 900, 16);
	addUnitType ("Hamster",    800, 16);

	PlayerInfo [string] playersTable;
	PlayerInfo totals;
	totals.name = "Total:";

	auto unitsTable = File ("units.binary", "rb")
	    .byLineCopy.join ('\n').parseJSON;

	long allHamstersGain = 0;
	long allUnitsHealth = 0;

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

		if (unitType == "Hamster")
		{
			allHamstersGain += hamsterMetalGain;
		}
		allUnitsHealth += healthByType[unitType];
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
		    `id="col-points" ` ~
		    `title="Wolf=1&#10;Ant=2&#10;Skunk=4&#10;Raccoon=8&#10;` ~
		    `Elephantor=16&#10;Hamster=16">Points</th>`);
		file.writefln !(`<th id="col-percent">Share</th>`);

		auto writePlayer (long i, ref PlayerInfo player)
		{
			file.writefln !(`<tr>`);
			file.writefln !(`<td class="amount">%s</td>`)
			    ((i >= 0) ? (i + 1) : players.length);
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

		auto writeStats ()
		{
			file.writefln !(`<tr>`);
			file.writefln !(`<td class="amount">&nbsp;</td>`);
			file.writefln !(`<td class="name">Owners:</td>`);
			foreach (line; unitTypes)
			{
				file.writefln !(`<td class="amount">` ~
				    `%.02f%%</td>`) (players.map !(player =>
				    player.amount.get (line, 0) > 0).sum (0) *
				    100.0 / players.length);
			}
			file.writefln !(`<td class="amount">&nbsp;</td>`);
			file.writefln !(`<td class="amount">&nbsp;</td>`);
			file.writefln !(`</tr>`);
		}

		writePlayer (-1, totals);
		writeStats ();
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
		writeStats ();
		file.writeln (`</tfoot>`);

		file.writeln (`</table>`);
		file.writeln (`<p height="5px"></p>`);

		auto allHourlyRepair = allUnitsHealth / 10 / 2;
		auto diff = allHamstersGain - allHourlyRepair;
		file.writeln (`<table class="log" ` ~
		    `id="general-table">`);
		file.writeln (`<tr>`);
		file.writeln (`<td class="header">How much metal ` ~
		    `can be mined by all hamsters in an hour:</td>`);
		file.writefln !(`<td class="amount">%s</td>`)
		    (toCommaNumber (allHamstersGain));
		file.writeln (`</tr>`);
		file.writeln (`<tr>`);
		file.writeln (`<td class="header">How much metal ` ~
		    `can be spent on repairs in an hour:</td>`);
		file.writefln !(`<td class="amount">%s</td>`)
		    (toCommaNumber (allHourlyRepair));
		file.writeln (`</tr>`);
		file.writeln (`<tr>`);
		file.writeln (`<td class="header">Difference:</td>`);
		file.writefln !(`<td class="amount">%s%s</td>`)
		    (diff >= 0 ? "" : "-", toCommaNumber (abs (diff)));
		file.writeln (`</tr>`);
		file.writeln (`</table>`);

		file.writefln !(`<script type="text/javascript" ` ~
		    `src="sort-players.js"></script>`);
		writeFooter (file);
	}

	return 0;
}
