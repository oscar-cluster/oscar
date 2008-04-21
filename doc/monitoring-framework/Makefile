
all: html pdf

html: monitoring_framework.sgml
	sgmltools -b onehtml monitoring_framework.sgml

pdf:  monitoring_framework.sgml
	dblatex  -o monitoring_framework.pdf monitoring_framework.sgml

clean:
	rm -f monitoring_framework.pdf monitoring_framework.html 
	rm -f *.html *.htm
	rm -rf html latex
	rm -f *~
