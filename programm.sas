
*data a;
	*set a *end = last;
	*if last;
*run;

data coef;
	input a1-a4 b1-b4;
	datalines;
	0.21 0.22 0.23 0.24 2.0 2.1 2.2 2.3
	; 
run;

data vec;
	input cell_1;
	datalines;
	0 
	;
run;

*--- структура вектора ---;
* cell_i -- текущее состояние i-ой клетки;
* time_i время до события ;
* event_i ;
*-------------------------;
/*%macro WeibGen(evt, a, b);*/
/*t = rand('WEIB',a,b); ev = &evt; output; */
/*%mend;*/

%macro EventSelector;
	data events;
		set coef;
	   t = rand('WEIB',a1,b1); ev = 1; output;
	   t = rand('WEIB',a2,b2); ev = 2; output;
	   t = rand('WEIB',a3,b3); ev = 3; output;
	   t = rand('WEIB',a4,b4); ev = 4; output;
	run;

	proc sort;
		by t;
	run;

	data events;
		set events (firstobs = 1 obs = 1);
	run;
%mend;

%macro event_analis(%n);
data vec;
	set vec
%mend;


%macro m;
*тут видимо макроитератор по всем клонам с;
data tmp;
	set sc_&c;
	*тут начинается макроитератор по всем i; 
	*i видимо надо хранить в макропеременной;
	if end = 1 then 
		do;
		select (cell_&i)
			when (0) ;
			when (1) 
				do; 
					*проставляем новое событие ли?;
					time_%eval(&i+1) = 0; event_%eval(&i+1) = 0; *создаем новую клетку;
				end;
			when (2) ;
			otherwise;
	*а тут заканчивается;
		end;
	*подцепляем в конец датасета новое наблюдение;
*а тут заканчивается макроитератор по клонам;

		*добавить к сету;
%mend;


proc format;
	value event_f 0 = "инициализация" 1 = "деление" 2 = "смерть";
run;
*---- инициализация данных ----;
data sc_1;
	input time_1 event_1;
	datalines;
	0 0;
run;

