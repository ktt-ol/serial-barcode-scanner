var encodings = {
	'0':'bwbWBwBwb',
	'1':'BwbWbwbwB',
	'2':'bwBWbwbwB',
	'3':'BwBWbwbwb',
	'4':'bwbWBwbwB',
	'5':'BwbWBwbwb',
	'6':'bwBWBwbwb',
	'7':'bwbWbwBwB',
	'8':'BwbWbwBwb',
	'9':'bwBWbwBwb',
	'A':'BwbwbWbwB',
	'B':'bwBwbWbwB',
	'C':'BwBwbWbwb',
	'D':'bwbwBWbwB',
	'E':'BwbwBWbwb',
	'F':'bwBwBWbwb',
	'G':'bwbwbWBwB',
	'H':'BwbwbWBwb',
	'I':'bwBwbWBwb',
	'J':'bwbwBWBwb',
	'K':'BwbwbwbWB',
	'L':'bwBwbwbWB',
	'M':'BwBwbwbWb',
	'N':'bwbwBwbWB',
	'O':'BwbwBwbWb',
	'P':'bwBwBwbWb',
	'Q':'bwbwbwBWB',
	'R':'BwbwbwBWb',
	'S':'bwBwbwBWb',
	'T':'bwbwBwBWb',
	'U':'BWbwbwbwB',
	'V':'bWBwbwbwB',
	'W':'BWBwbwbwb',
	'X':'bWbwBwbwB',
	'Y':'BWbwBwbwb',
	'Z':'bWBwBwbwb',
	'-':'bWbwbwBwB',
	'.':'BWbwbwBwb',
	' ':'bWBwbwBwb',
	'$':'bWbWbWbwb',
	'/':'bWbWbwbWb',
	'+':'bWbwbWbWb',
	'%':'bwbWbWbWb',
	'*':'bWbwBwBwb'
}

var height = 100;
var paintText = true;
var canvas;
var ctx;

var code39_init = function() {
	canvas = $('#barcode')[0];
	ctx = canvas.getContext("2d");
}

var code39_checksum = function(barcode) {
	var charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%";
	var subtotal = 0;
	var c;

	for (c in barcode) {
		subtotal += charset.indexOf(barcode[c]);
	}

	return charset[subtotal%43];
}

var code39_draw = function(text, add_checksum) {
	var showtext = text;

	if(add_checksum) {
		text += code39_checksum(text);
		showtext += " ";
	}

	text = "*" + text + "*";
	showtext = " " + showtext + " ";

	var txtLength = text.length;
	var totalWidth = txtLength*15 +txtLength - 1;
	cwidth = totalWidth+30;

	ctx.clearRect(0,0,canvas.width,canvas.height);

	canvas.style.height = canvas.height = height;
	canvas.style.width = canvas.width = cwidth ;
	ctx.fillStyle = "rgb(255,255,255)";
	ctx.fillRect(0,0,canvas.width,canvas.height);

	var i,j;

	/* Rounding to prevent antialising */
	var currentx = Math.round(cwidth/2-totalWidth/2), currenty = 20;

	/* wides are 3x width of narrow */
	var widewidth = 3;

	var barheight = 80;

	if(paintText) {
		barheight -= 20;
	}

	for(i=0;i<text.length;i++) {
		var code = encodings[text[i]];
		if (!code) {
			code = encodings['-'];
		}

		for(j=0;j<code.length;j++) {
			if (j%2==0) {
				/* black */
				ctx.fillStyle = "rgb(0,0,0)";
			} else {
				/* white */
				ctx.fillStyle = "rgb(255,255,255)";
			}

			if (code.charCodeAt(j)<91) {
				/* wide */
				ctx.fillRect (currentx, currenty, widewidth, barheight);
				currentx += 3;
			} else {
				/* narrow */
				ctx.fillRect (currentx, currenty, 1, barheight);
				currentx += 1;
			}

			if (paintText && (j==5) && (typeof ctx.fillText == 'function')) {
				ctx.fillStyle = "rgb(0,0,0)";
				ctx.fillText(showtext[i], currentx, 90);
			}
		}

		if (i!=text.length-1) {
			/* draw narrow white as divider */
			ctx.fillStyle = "rgb(255,255,255)";
			ctx.fillRect (currentx, currenty, 1, barheight);
			currentx += 1;
		}
	}
}

var code39_url = function() {
	return canvas.toDataURL();
}
