#!/usr/bin/env ruby -w
# encoding: UTF-8

require "csv"

#csv input "userid,firstname,lastname"

@template = %q{
	\documentclass[a4paper]{article}
	\usepackage[utf8]{inputenc}
	\usepackage{graphicx}
	\usepackage{longtable}
	\usepackage[a4paper,margin=1cm,bmargin=2cm]{geometry}
	\renewcommand{\familydefault}{\sfdefault}
	\title{Shopsystem Nutzerliste}
	\author{Kreativitaet trifft Technik}
	\date{\today}
	\begin{document}
		\maketitle
		\begin{center}
		\begin{longtable}{|c|c|}
			%s
		\end{longtable}
	\end{center}
	\end{document}}

@line = %q{
	\hline
	%s
	\hline
	%s
	\hline}

@graphics = %q{ \includegraphics{%s} %s}
@name = %q{ %s %s (%s) %s}

@csv = CSV.read(ARGV[0])

#generate barcodes
@csv.each{|r|
	system("barcode -n -E -b 'USER %s' -o 'barcodes/%s.eps' -u mm -g 80x30 -e 39\n" % [r[0], r[0]])
}

#generate latex
tmp = ""
graphics = ""
name = ""
1.upto(@csv.length){|i|
	le = i % 2 == 0 || i >= @csv.length
	sign = le ? "\\\\" : "&"
	graphics += @graphics % [@csv[i-1][0], sign]
	name += @name % [@csv[i-1][1], @csv[i-1][2], @csv[i-1][0], sign]
	if le
		tmp += @line % [graphics, name]
		graphics = ""
		name = ""
	end
}
File.open("barcodes/barcode.latex", "w+"){|f| f.write(@template % tmp)}
