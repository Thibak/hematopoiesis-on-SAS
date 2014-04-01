

%macro colonyIt (it);
	*датасет-болванка для правильной обработки первого вызова;
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
*------- отсюда итератор --------;

	%let N = 50;

	%do cells = 1 %to &it; * почему cells итератор абсолютно непонятно;

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
			&cell_N = 1; *к концу будем иметь тут суммарное количество клеток;
			&newCell = 0;
			ColonyStatus = 0;
			dummy = .; *заглушка для отбора последней записи;

			do i = 1 to &N; *итератор записей (т.е. циклов деления);
				&cell_N + &newCell; *прибавляем новые клетки из предыдущей итерации;
				*Счетчики новых клеток и кумулятивно-клеток;
				if &cell_N > &N then leave;
				&newCell = 0; *обнуляем счетчик новых клеток;
				&liveCells = 0; * счетчик живых клеток ;
				do cell_i = 1 to &cell_N; *пробегаем по всем клеткам;
					*селектор события;
					do ev = 1 to DIM(cur_ev);
						cur_ev[ev] = rand('WEIB',a[ev],b[ev]); 
					end;
					do ev = 1 to DIM(cur_ev);
			         	if cur_ev[ev] = min(of cur_ev[*]) 
			            then do;
			          		eventIndx=ev; *мне нужен индекс для определения события;
			          		*MaxValueVar=vname(cur_ev(i));
			         	 	leave;
			     		end; 
					end;
					/*----------------*/

					select (event[cell_i]);
							when (0);
							*инициализация;
							when (1) 
								do;
								*деление;
									&newCell+1;
									if &cell_N+&newCell > &N then leave;
									cell[&cell_N+&newCell]  = 1;  
									time[&cell_N+&newCell]  = 0; 
									event[&cell_N+&newCell] = 0; *создаем новую клетку;
								end;
							when (2) 
								do; 
								*смерть;
									cell[cell_i] = .;
									event[cell_i] = .;
									time[cell_i] = .;
								end;
							otherwise;
						end;
					*генерим новое событие, если клетка не мертва;
					if event[cell_i] in (0,1) then
						do; 
							cell[cell_i]  = 1;
							event[cell_i] = eventIndx;
							time[cell_i] = min(of cur_ev[*]) ;
							CumTime[cell_i] + time[cell_i];
							&liveCells+1;
						end;
				end;
				
				/*блок рссчета показателей для вытакивания в конечный вектор-саммари*/
				CumMaxTime + max(of time[*]); 
				&cellDeath = &cell_N - &liveCells;
				N = &N;

				* Количество делений = тому, что в следующей строке;
				* Количество клеток = &cell_N;
				* Время жизни популяции = CumMaxTime;
				* количество актов деления = i ;
				* Исход (вымирание, экспонента) = ColonyStatus;
				* Количество клеток на выходе (живых) = liveCells;
				* Количество смертей/выходов -- продукция = cell_N - liveCells  т.е. вычисляемый параметр;
				
				/**/
				if max(of cell[*]) = . then ColonyStatus = 1; *индикатор вымирания колонии, если он не достигается, то колония считается экспоненциально разросшийся;
				if ColonyStatus = 1 then 
					do;
						output;
						leave;

					end;
					else output;
			end;
			
			label 
				ColonyStatus = статус колонии на выходе
				liveCells = количество живых клеток в колонии
			;
			
		run;

		* складываем скалярные величины в специальный датасет ;
		data tmpStatVector (keep = cell_N i CumMaxTime ColonyStatus liveCells );
			*Вытаскиваем из последней записи ;
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

/**обработчик горизонтальных векторов дописать;*/
/*		data tmpStatVector (keep = cell_N i CumMaxTime ColonyStatus liveCells );*/
/*			*Вытаскиваем из последней записи ;*/
/*			set colony;*/
/*			by dummy;*/
/*			if last.dummy;*/
/*			cell_N = &cell_N;*/
/*			liveCells = &liveCells;*/
/*		run;*/
/**------------------------------------------;*/
		*прицепляем динамику изменения состава популяции новым столбцом ;

		* динамика деления ;
		data tmp;
			set colony (keep = &newCell);
		run;

		data newCells;
			merge newCells tmp;
		run;

		* динамика ;
		data tmp;
			set colony (keep = &cell_N);
		run;

		data cell_Ns;
			merge cell_Ns tmp;
		run;

		* динамика ;
		data tmp;
			set colony (keep = &liveCells);
		run;

		data liveCellss;
			merge liveCellss tmp;
		run;

		* динамика ;
		data tmp;
			set colony (keep = &cellDeath);
		run;

		data cellDeaths;
			merge cellDeaths tmp;
		run;
	%end;

		*----- конец итератора -----;
%mend colonyIt;



*-------------------------------------------------------------------------;
*-------------------------------------------------------------------------;
*-------------------------------------------------------------------------;
*-------------------------------------------------------------------------;
*-------------------------------------------------------------------------;
*-------------------------------------------------------------------------;



*----- подготовка переменных -----;
proc format;
	value event_f 0 = "инициализация" 1 = "деление" 2 = "дифференцировка";
	value ColonyStatus 0 = "Колония жива" 1 = "Колония вымерла";
run;

*----- подготовка данных -----;

%macro exp(num, str, begin, end, step);
*str имеет специальный формат, 3 числа, и одно &var -- итерируемый параметр;
*например "2 2 &var 2" ;
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
*тут выкладываем в датасет;
	%end;
	*тут выводим результат работы, например график;
%mend exp;

/*proc print data = result;*/
/*run;*/

/*proc means data = result;*/
/*	var cell_N i CumMaxTime ColonyStatus liveCells;*/
/*run;*/


*Это реализуется при помощи функции MEAN, в датастепе, куда мы складываем параметры и MEAN а потом кластеризуем!;
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

