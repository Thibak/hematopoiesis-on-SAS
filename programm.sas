

proc format;
	value event_f 0 = "�������" 1 = "������";
run;

data sc_1;
	input cell_1 event_1;
	datalines;
	0 0;
run;

