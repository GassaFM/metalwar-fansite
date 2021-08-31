// Author: Ivan Kazmenko (gassa@mail.ru)
// Inspired by: https://stackoverflow.com/questions/10683712#57080195
const tableToSort = document.getElementById ('units-table');
document.getElementById ('col-id').addEventListener ('click',
    event => {sortTable (tableToSort,  1 * 3, +1, 'num');});
document.getElementById ('col-owner').addEventListener ('click',
    event => {sortTable (tableToSort,  2 * 3, +1, 'str');});
document.getElementById ('col-x').addEventListener ('click',
    event => {sortTable (tableToSort,  3 * 3, +1, 'num');});
document.getElementById ('col-y').addEventListener ('click',
    event => {sortTable (tableToSort,  4 * 3, +1, 'num');});
document.getElementById ('col-name').addEventListener ('click',
    event => {sortTable (tableToSort,  5 * 3, +1, 'str');});
document.getElementById ('col-health').addEventListener ('click',
    event => {sortTable (tableToSort,  6 * 3, +1, 'frac');});
document.getElementById ('col-cargo').addEventListener ('click',
    event => {sortTable (tableToSort,  7 * 3, +1, 'frac');});

function sortTable (table, col, dir, type) {
	const body = table.querySelector ('tbody');
	const data = getData (body);
	data.sort ((a, b) => {
		mult = (a[col][0] == '-') ? -1 : +1;
		if (type == 'num') {
			if (a[col].length != b[col].length) {
				return ((a[col].length < b[col].length) ?
					-dir : +dir) * mult;
			}
		} else if (type == 'frac') {
			let a0 = a[col].substr (0, a[col].indexOf ('/')) | 0;
			let b0 = b[col].substr (0, b[col].indexOf ('/')) | 0;
			let a1 = a[col].substr (a[col].indexOf ('/') + 1) | 0;
			let b1 = b[col].substr (b[col].indexOf ('/') + 1) | 0;
			if (a0 != b0) {
				return ((a0 < b0) ?
					-dir : +dir) * mult;
			}
			if (a1 != b1) {
				return ((a1 < b1) ? -dir : +dir) * mult;
			}
			return 0;
		}
		if (a[col] != b[col]) {
			return ((a[col] < b[col]) ? -dir : +dir) * mult;
		}
		return 0;
	});
	putData (body, data);
}

function getData (body) {
	const data = [];
	body.querySelectorAll ('tr').forEach (row => {
		const line = [];
		row.querySelectorAll ('td').forEach (cell => {
			line.push (cell.innerText);
			line.push (cell.getAttribute ('class'));
			line.push (cell.getAttribute ('style'));
		});
		data.push (line);
	});
	return data;
}

function putData (body, data) {
	body.querySelectorAll ('tr').forEach ((row, i) => {
		const line = data[i];
		row.querySelectorAll ('td').forEach ((cell, j) => {
			if (j >= 1) {
				cell.innerText = line[j * 3 + 0];
				cell.setAttribute ('class', line[j * 3 + 1]);
				cell.setAttribute ('style', line[j * 3 + 2]);
			}
		});
	});
}
