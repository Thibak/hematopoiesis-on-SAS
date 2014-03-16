



%let CellNumber = 1;
%let CTime = 0;
%let CEvent = 0;
*--- структура вектора ---;
* cell_i -- текущее состояние i-ой клетки;
	* 1 -- жива и здорова;
	* . -- умерла ;
* time_i -- время до события ;
* event_i -- Идентификатор события;
	*value event_f 0 = "инициализация" 1 = "деление" 2 = "смерть";
*-------------------------;

%macro EventSelector(n=1);
	data events;
		set coef_&n;
	   t = rand('WEIB',a1,b1); ev = 1; output;
	   t = rand('WEIB',a2,b2); ev = 2; output;
	  * t = rand('WEIB',a3,b3); *ev = 3; *output;
	  * t = rand('WEIB',a4,b4); *ev = 4; *output;
	run;

	proc sort data = events;
		by t;
	run;

	data _null_;
		set events (firstobs = 1 obs = 1); *берем только одно, первое наблюдение;
		call symput('CTime',t);
		call symput('CEvent',ev);
	run;
%mend;



%macro ColonyUpdate(n=1);
	data vec_&n;
		set vec_&n;
		call symput('CellNumber', N);
		%do i = 1 %to &CellNumber;
			select (event_&i);
				when (0); *инициализация;
				when (1) 
					do; *деление;
						cell_%eval(&i+1) = 1;
						time_%eval(&i+1) = 0; 
						event_%eval(&i+1) = 0; *создаем новую клетку;
						N = N+1;
					end;
				when (2) 
					do; *смерть;
						cell_&i = .;
						event_&i = .;
						time_&i = .;
					end;
				otherwise;
	/*---------*/
			if event_&i in (0,1) then 
				do; 
					CALL execute ('EventSelector(&n)');
					event_&i = &CEvent;
					time_&i = &CTime;
				end;
		%end;
	run;

	data 
%mend;

*----- макросы готовы -----;

*----- подготовка переменных -----;
proc format;
	value event_f 0 = "инициализация" 1 = "деление" 2 = "смерть";
run;

*----- подготовка данных -----;



data coef_1;
	input a1-a4 b1-b4;
	datalines;
	0.21 0.22 0.23 0.24 2.0 2.1 2.2 2.3
	; 
run;

data vec_1;
	input cell_1 time_1 event_1 N; *N -- количество клеток;
	datalines; 
	0 0 0 1
	;
run;

/*------------------------------------------------------*/
*---- инициализация данных ----;
data sc_1;
	input time_1 event_1;
	datalines;
	0 0;
run;

