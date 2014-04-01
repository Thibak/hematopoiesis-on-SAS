

%macro colonyIt (it);
	*�������-�������� ��� ���������� ��������� ������� ������;
	data newCells;
	run;
	data result;
	run;
	data cell_Ns;
	run;
	data liveCellss;
	run;
	data cellDeaths;
	run;
*------- ������ �������� --------;

	%let N = 50;

	%do cells = 1 %to &it; * ������ cells �������� ��������� ���������;

	%let newCell = newCell&cells;
	%let cell_N = cell_N&cells;
	%let liveCells = liveCells&cells;
	%let cellDeath = cellDeath&cells;

		data colony;
			set coef_1;
			array a[*] a1-a4;
			array b[*] b1-b4;

			array  cell[&N] (0);
			array  time[&N] (0);
			array  CumTime[&N] (0);
			array  event[&N] (0);

			array cur_ev[2];
			&cell_N = 1; *� ����� ����� ����� ��� ��������� ���������� ������;
			&newCell = 0;
			ColonyStatus = 0;
			dummy = .; *�������� ��� ������ ��������� ������;

			do i = 1 to &N; *�������� ������� (�.�. ������ �������);
				&cell_N + &newCell; *���������� ����� ������ �� ���������� ��������;
				*�������� ����� ������ � �����������-������;
				if &cell_N > &N then leave;
				&newCell = 0; *�������� ������� ����� ������;
				&liveCells = 0; * ������� ����� ������ ;
				do cell_i = 1 to &cell_N; *��������� �� ���� �������;
					*�������� �������;
					do ev = 1 to DIM(cur_ev);
						cur_ev[ev] = rand('WEIB',a[ev],b[ev]); 
					end;
					do ev = 1 to DIM(cur_ev);
			         	if cur_ev[ev] = min(of cur_ev[*]) 
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
									if &cell_N+&newCell > &N then leave;
									cell[&cell_N+&newCell]  = 1;  
									time[&cell_N+&newCell]  = 0; 
									event[&cell_N+&newCell] = 0; *������� ����� ������;
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
							time[cell_i] = min(of cur_ev[*]) ;
							CumTime[cell_i] + time[cell_i];
							&liveCells+1;
						end;
				end;
				
				/*���� ������� ����������� ��� ����������� � �������� ������-�������*/
				CumMaxTime + max(of time[*]); 
				&cellDeath = &cell_N - &liveCells;
				N = &N;

				* ���������� ������� = ����, ��� � ��������� ������;
				* ���������� ������ = &cell_N;
				* ����� ����� ��������� = CumMaxTime;
				* ���������� ����� ������� = i ;
				* ����� (���������, ����������) = ColonyStatus;
				* ���������� ������ �� ������ (�����) = liveCells;
				* ���������� �������/������� -- ��������� = cell_N - liveCells  �.�. ����������� ��������;
				
				/**/
				if max(of cell[*]) = . then ColonyStatus = 1; *��������� ��������� �������, ���� �� �� �����������, �� ������� ��������� ��������������� �����������;
				if ColonyStatus = 1 then 
					do;
						output;
						leave;

					end;
					else output;
			end;
			
			label 
				ColonyStatus = ������ ������� �� ������
				liveCells = ���������� ����� ������ � �������
			;
			
		run;

		* ���������� ��������� �������� � ����������� ������� ;
		data tmpStatVector (keep = cell_N i CumMaxTime ColonyStatus liveCells );
			*����������� �� ��������� ������ ;
			set colony;
			by dummy;
			if last.dummy;
			cell_N = &cell_N;
			liveCells = &liveCells;
		run;

		data result;
			set result tmpStatVector;
			cellDeath = cell_N - liveCells;
		run;

/**���������� �������������� �������� ��������;*/
/*		data tmpStatVector (keep = cell_N i CumMaxTime ColonyStatus liveCells );*/
/*			*����������� �� ��������� ������ ;*/
/*			set colony;*/
/*			by dummy;*/
/*			if last.dummy;*/
/*			cell_N = &cell_N;*/
/*			liveCells = &liveCells;*/
/*		run;*/
/**------------------------------------------;*/
		*���������� �������� ��������� ������� ��������� ����� �������� ;

		* �������� ������� ;
		data tmp;
			set colony (keep = &newCell);
		run;

		data newCells;
			merge newCells tmp;
		run;

		* �������� ;
		data tmp;
			set colony (keep = &cell_N);
		run;

		data cell_Ns;
			merge cell_Ns tmp;
		run;

		* �������� ;
		data tmp;
			set colony (keep = &liveCells);
		run;

		data liveCellss;
			merge liveCellss tmp;
		run;

		* �������� ;
		data tmp;
			set colony (keep = &cellDeath);
		run;

		data cellDeaths;
			merge cellDeaths tmp;
		run;
	%end;

		*----- ����� ��������� -----;
%mend colonyIt;



*-------------------------------------------------------------------------;
*-------------------------------------------------------------------------;
*-------------------------------------------------------------------------;
*-------------------------------------------------------------------------;
*-------------------------------------------------------------------------;
*-------------------------------------------------------------------------;



*----- ���������� ���������� -----;
proc format;
	value event_f 0 = "�������������" 1 = "�������" 2 = "���������������";
	value ColonyStatus 0 = "������� ����" 1 = "������� �������";
run;

*----- ���������� ������ -----;

%macro exp(num, str, begin, end, step);
*str ����� ����������� ������, 3 �����, � ���� &var -- ����������� ��������;
*�������� "2 2 &var 2" ;
	%do var = &begin %to &end %by &step;
		data coef_1;
			array a[*] a1-a2;
			array b[*] b1-b2;
			input a[*] b[*];
			datalines;
			&str
			; 
		run;
		%colonyIt(50);
*��� ����������� � �������;
	%end;
	*��� ������� ��������� ������, �������� ������;
%mend exp;

/*proc print data = result;*/
/*run;*/

/*proc means data = result;*/
/*	var cell_N i CumMaxTime ColonyStatus liveCells;*/
/*run;*/


*��� ����������� ��� ������ ������� MEAN, � ���������, ���� �� ���������� ��������� � MEAN � ����� ������������!;
/*proc means data = result;*/
/*	var N ColonyStatus a1 b1 a2 b2;*/
/*run;*/

/*proc print data = newCells;*/
/*run;*/
/**/
/*proc print data = cell_Ns;*/
/*run;*/
/**/
/*proc print data = liveCellss;*/
/*run;*/
/**/
/*proc print data = cellDeaths;*/
/*run;*/

