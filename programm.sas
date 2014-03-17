



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

%macro EventSelector(n);
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



%macro ColonyUpdate(n);

*	%EventSelector(&n);

	data vec_&n;
		set vec_&n;
			call symput('CellNumber', N);
	run; 
%let k = 1; *количество клеток, созданных на этом этапе;
%do i = 1 %to &CellNumber;
	%EventSelector(&n); *генерируем новое событие. Оно может и не понадобиться...;
	data vec_&n;
		set vec_&n;
		/*резюме: не работает нижеследующий цикл. Можно попробовать его вынести. 
		Сразу понятно, что генератор случайных событий отрабатывается один раз
		В принципе, нам совершенно нет необходимости выполнять это на одном дата-шаге. 
		Самое главное
	сделал.
		*/
put "------------------&i--------------------";
			select (event_&i);
				when (0) put "------------------&i-------------------- when (0)"; *инициализация;
				when (1) 
					do; *деление;
						put "------------------&i-------------------- when (1)";
						cell_%eval(&CellNumber+&k) = 1;
						time_%eval(&CellNumber+&k) = 0; 
						event_%eval(&CellNumber+&k) = 0; *создаем новую клетку;
						%let k = %eval(&k+1);
						div_%eval(&CellNumber+&k) = %eval(&CellNumber+&k);
						N = N+1;
					end;
				when (2) 
					do; *смерть;
					put "------------------&i-------------------- when (2)";
						cell_&i = .;
						event_&i = .;
						time_&i = .;
						death_&i = &i;
					end;
				otherwise put "------------------&i-------------------- when otherwise";
			end;
				put "point";
	/*---------*/
			if event_&i in (0,1) then 
				do; 
					event_&i = &CEvent;
					time_&i = &CTime;
				end;
		
	run;

	proc print;
	run;
%end;
	*Присоединяем полученный вектор;
	data colony_&n;
		set colony_&n vec_&n;
	run;

	proc print;
	run;
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
	0.21 0.22 0.1 0.24 2.0 2.1 2.2 2.3
	; 
run;

data vec_1;
	input cell_1 time_1 event_1 N; *N -- количество клеток;
	datalines; 
	0 0 0 1
	;
run;

data colony_1;
	set vec_1;
run;

%ColonyUpdate(1);
%ColonyUpdate(1);
%ColonyUpdate(1);
%ColonyUpdate(1);
%ColonyUpdate(1);
%ColonyUpdate(1);
%ColonyUpdate(1);
%ColonyUpdate(1);
%ColonyUpdate(1);

%ColonyUpdate(1);

%ColonyUpdate(1);

%ColonyUpdate(1);

%ColonyUpdate(1);

%ColonyUpdate(1);

%ColonyUpdate(1);




proc print;
run;

