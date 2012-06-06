#!/usr/bin/env ruby -w
# encoding: UTF-8

require "csv"

#csv input "userid,firstname,lastname"

@template = %q{
	\documentclass[a4paper,landscape]{article}
	\usepackage[utf8]{inputenc}
	\usepackage{graphicx}
	\usepackage{longtable}
	\usepackage[top=0.5cm,right=0.5cm,bottom=0.5cm,left=0.5cm,landscape]{geometry}
	\renewcommand{\familydefault}{\sfdefault}
	\title{Barcodelist}
	\author{Kreativitaet trifft Technik}
	\date{\today}
	\begin{document}
		\begin{center}
		\begin{longtable}{|c|c|c|}
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
@name = %q{ %s %s %s}

@csv = CSV.read(ARGV[0])

#generate barcodes
@csv.each{|r| 
	system("barcode -n -E -b 'USER %s' -o '%s.eps' -e 39\n" % [r[0], r[0]])
}

#generate latex
tmp = ""
graphics = ""
name = ""
1.upto(@csv.length){|i|
	le = i % 3 == 0 || i >= @csv.length
	sign = le ? "\\\\" : "&"
	graphics += @graphics % [@csv[i-1][0], sign]
	name += @name % [@csv[i-1][1], @csv[i-1][2], sign]
	if le 
		tmp += @line % [graphics, name] 
		graphics = ""
		name = ""
	end
}
File.open("barcode.latex", "w+"){|f| f.write(@template % tmp)}
