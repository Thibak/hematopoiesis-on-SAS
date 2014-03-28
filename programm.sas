

*----- ���������� ���������� -----;
proc format;
	value event_f 0 = "�������������" 1 = "�������" 2 = "������";
run;

*----- ���������� ������ -----;

data coef_1;
	array a[*] a1-a4;
	array b[*] b1-b4;
	input a[*] b[*];
	datalines;
	0.21 0.02 0.5 0.24 2.0 2.1 2.2 2.3
	; 
run;

*�������-�������� ��� ���������� ��������� ������� ������;
/*data newCells;*/
/*run;*/
/*%let cells = 0;*/



%let N = 100;
%let cells = %eval(&cells+1);
%let newCell = newCell&cells;

data colony;
	set coef_1;
	array a[*] a1-a4;
	array b[*] b1-b4;

	array  cell[&N] (0);
	array  time[&N] (0);
	array  CumTime[&N] (0);
	array event[&N] (0);

	array cur_ev[2];
	cell_N = 1; *� ����� ����� ����� ��� ��������� ���������� ������;
	&newCell = 0;
	ColonyStatus = 0;
	dummy = .; *�������� ��� ������ ��������� ������;

	do i = 1 to &N; *�������� ������� (�.�. ������ �������);
		cell_N + &newCell; *���������� ����� ������ �� ���������� ��������;
		if cell_N > &N then leave;
		&newCell = 0; *�������� ������� ����� ������;
		do cell_i = 1 to cell_N; *��������� �� ���� �������;
			*�������� �������;
			do ev = 1 to DIM(cur_ev);
				cur_ev[ev] = rand('WEIB',a[ev],b[ev]); 
			end;
			do ev = 1 to DIM(cur_ev);
	         	if cur_ev[ev] = max(of cur_ev[*]) 
	            then do;
	          		eventIndx=ev; *��� ����� ������ ��� ����������� �������;
	          		*MaxValueVar=vname(cur_ev(i));
	         	 	leave;
	     		end; 
			end;
			/*----------------*/

			select (event[cell_i]);
					when (0);
					*�������������;
					when (1) 
						do;
						*�������;
							&newCell+1;
							if cell_N+&newCell > &N then leave;
							cell[cell_N+&newCell]  = 1;  
							time[cell_N+&newCell]  = 0; 
							event[cell_N+&newCell] = 0; *������� ����� ������;
						end;
					when (2) 
						do; 
						*������;
							cell[cell_i] = .;
							event[cell_i] = .;
							time[cell_i] = .;
						end;
					otherwise;
				end;
			*������� ����� �������, ���� ������ �� ������;
			if event[cell_i] in (0,1) then
				do; 
					cell[cell_i]  = 1;
					event[cell_i] = eventIndx;
					time[cell_i] = max(of cur_ev[*]) ;
					CumTime[cell_i] + time[cell_i];
				end;
		end;
		
		if max(of cell[*]) = . then ColonyStatus = 1;
		if ColonyStatus = 1 then 
			do;
				output;
				leave;
			end;
			else output;
	end;

run;


data tmpStatVector (keep = cell_N);
	*����������� �� ��������� ������ ;
	set colony;
	if last.dummy;
run;

*���������� �������� ��������� ������� ��������� ����� �������� ;

data tmp;
	set colony (keep = &newCell);
run;

data newCells;
	merge newCells tmp;
run;


proc print data = tmp;
run;

proc print data = newCells;
run;
