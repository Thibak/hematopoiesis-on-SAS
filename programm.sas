options nosource nonotes;

%macro colonyIt (it,a1,a2,b1,b2,N, borderN);
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

    %do cells = 1 %to &it; * ������ cells �������� ��������� ���������;

    %let newCell = newCell&cells;
    %let cell_N = cell_N&cells;
    %let liveCells = liveCells&cells;
    %let cellDeath = cellDeath&cells;

        data colony;

            array  cell[&N];
            array  time[&N];
            array  CumTime[&N];
            array  event[&N];

			cell[1] = 0;
            time[1] = 0;
            CumTime[1] = 0;
            event[1] = 0;

            array cur_ev[2];
            &cell_N = 1; *� ����� ����� ����� ��� ��������� ���������� ������;
            &newCell = 0;
            ColonyStatus = 1;
			brdr = 0;
            dummy = .; *�������� ��� ������ ��������� ������;

            do i = 1 to &N; *�������� ������� (�.�. ������ �������);
                &cell_N + &newCell; *���������� ����� ������ �� ���������� ��������;
                *�������� ����� ������ � �����������-������;
                if &cell_N > &N then leave;
                &newCell = 0; *�������� ������� ����� ������;
                &liveCells = 0; * ������� ����� ������ ;
                do cell_i = 1 to &cell_N; *��������� �� ���� �������;
                    *�������� �������;
                  
                    cur_ev[1] = rand('WEIB',&a1,&b1);
                    cur_ev[2] = rand('WEIB',&a2,&b2);

					*a is a numeric shape parameter.;
					*b is a numeric scale parameter.;

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
				if &cell_N > &borderN then brdr = 1;
                N = &N;

                * ���������� ������� = ����, ��� � ��������� ������;
                * ���������� ������ = &cell_N;
                * ����� ����� ��������� = CumMaxTime;
                * ���������� ����� ������� = i ;
                * ����� (���������, ����������) = ColonyStatus;
                * ���������� ������ �� ������ (�����) = liveCells;
                * ���������� �������/������� -- ��������� = cell_N - liveCells  �.�. ����������� ��������;

                /**/
                if max(of cell[*]) = . then ColonyStatus = 0; *��������� ��������� �������, ���� �� �� �����������, �� ������� ��������� ��������������� �����������;
                if ColonyStatus = 0 then
                    do;
                        output;
                        leave;

                    end;
                    else output;
            end;
        run;

        * ���������� ��������� �������� � ����������� ������� ;
        data tmpStatVector (keep = cell_N i CumMaxTime ColonyStatus liveCells brdr);
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
			LCondPr = .;
			if brdr = 1 and ColonyStatus = 1 then LCondPr = 1;
			if brdr = 1 and ColonyStatus = 0 then LCondPr = 0;
        run;

/**���������� �������������� �������� ��������;*/
/*      data tmpStatVector (keep = cell_N i CumMaxTime ColonyStatus liveCells );*/
/*          *����������� �� ��������� ������ ;*/
/*          set colony;*/
/*          by dummy;*/
/*          if last.dummy;*/
/*          cell_N = &cell_N;*/
/*          liveCells = &liveCells;*/
/*      run;*/
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
	*��� ����� ���������� � ������������� �������� ���������� �� �������, ������� ����������, ���� �� �� ����������� ������;
	*data FinalResult;
	proc means data = result  ; *NOPRINT;
		output out = CurMeanRes  
			mean(ColonyStatus LCondPr) = meanRes meanLCondPr 
			n(ColonyStatus LCondPr) = nRes nLCondPr 
			STDERR(ColonyStatus LCondPr) =  stdColonyStatus stdLCondPr;
	run;

/* �������� ������� ���������� ����������� �������	*/

	data ExpRes;
		set ExpRes CurMeanRes;
		if (a1=.)or(a2=.)or(b1=.)or(b2=.) then 
			do;
				a1=&a1;
				a2=&a2;
				b1=&b1;
				b2=&b2;
				brdr = &borderN;
			end;
	run;

/*	proc print data = ExpRes;*/
/*	run;*/
%mend colonyIt;

%macro plotSTD(dowhlc, date, mean, std);
	data dowhlc;
		set &dowhlc;
		high = &mean + &std;
		low = &mean - &std;
	run;
	
	data dowhlc;
	   set dowhlc;
	   Dow=high; output;
	   Dow=low; output;
	   Dow=&mean; output;
	run;

	symbol1 interpol=hiloctj;

	proc gplot data=dowhlc;
	   plot dow*&date /;
	run;
	quit;
%mend;
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
title1 " ";


data coef;
	array a[*] a1-a2 (1 1);
	array b[*] b1-b2 (1 1);

	limit = 100;
/*border = 5 ;*/
		do border = 0 to 30 by 1;
			output;
		end;


/*	do a1 = 0 to 2 by .2;*/
/*		output;*/
/*	end;*/
/*	a1 = 1;*/
/**/
/*	do a2 = 0 to 2 by .2;*/
/*		output;*/
/*	end;*/
/*	a2 = 1;*/

/*	do b1 = 0.01 to 2 by .1;*/
/*		do b2 = 0.01 to 2 by .1;*/
/*			output;*/
/*		end;*/
/*	end;*/
/*	b1 = 1;*/

/*	do b2 = .1 to 5 by .1;*/
/*		output;*/
/*	end;*/
/*	b2 = 1;*/

/*	input a[*] b[*];*/
/*	datalines;*/
/*	1 1 1 1.0 */
/*	1 1 1 1.1 */
/*	1 1 1 1.2 */
/*	1 1 1 1.3 */
/*	;*/
run;

*��������� �����������: ��������� ������� � "������" ������������, � ����� ��������� �� ���� ������. ;

	data ExpRes;
	run;

%let iteration = 500; *�� �������� ������� ���������� ������� ������ ���������� �������� ������� �� ��������;
data _null_;
	set coef;
	call execute('%colonyIt(&iteration,'||a1||','||a2||','||b1||','||b2||','||limit||','||border||')');
run;

/*options source notes;*/

symbol1 interpol=join value=diamondfilled   color=vibg height=1;                                                                         
symbol2 interpol=join value=trianglefilled color=depk height=1;
/*symbol3 interpol=join value=diamondfilled  color=mob  height=2;*/
legend1 label=none frame;


proc gplot data=ExpRes;
 plot (meanRes meanLCondPr)*brdr /overlay legend=legend1; 
* haxis=45 to 155 by 10;
run;
quit;

  

%plotSTD(ExpRes, brdr, meanLCondPr, stdLCondPr);



*https://support.sas.com/documentation/cdl/en/statug/63033/HTML/default/viewer.htm#statug_nlin_sect036.htm;
************* �������� ��� � �������� ������������. ������� ��� ���������� ������������� ������������ �� ���������� ***************;


/*proc g3grid data=ExpRes out=ExpRes3D;*/
/*   grid b1*b2 = meanRes meanLCondPr/ join; * spline smooth=.05;*/
/*run;*/
/**/
/*proc gcontour data=ExpRes3D;*/
/*   plot b1*b2 = meanRes;*/
/*   plot b1*b2 = meanLCondPr;*/
/*/overlay*/
/*run;*/
/*quit;*/
/**/
/**/
/*proc g3d data=ExpRes3D;*/
/*	plot b1*b2 = meanRes/ rotate = 250;*/
/*	plot b1*b2 = meanLCondPr/ rotate = 140;*/
/*run;*/
/*quit;*/




