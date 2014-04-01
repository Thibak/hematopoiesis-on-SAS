

%macro colonyIt (it);
*------- отсюда итератор --------;

	%let N = 10;
	%let cells = 0;

	%do cells = 1 %to &it; 

	%let newCell = newCell&cells;
	%let cell_N = cell_N&cells;

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
			dummy = .; *заглушка дл€ отбора последней записи;

			do i = 1 to &N; *итератор записей (т.е. циклов делени€);
				&cell_N + &newCell; *прибавл€ем новые клетки из предыдущей итерации;
				*—четчики новых клеток и кумул€тивно-клеток;
				if &cell_N > &N then leave;
				&newCell = 0; *обнул€ем счетчик новых клеток;
				liveCells = 0; * счетчик живых клеток ;
				do cell_i = 1 to &cell_N; *пробегаем по всем клеткам;
					*селектор событи€;
					do ev = 1 to DIM(cur_ev);
						cur_ev[ev] = rand('WEIB',a[ev],b[ev]); 
					end;
					do ev = 1 to DIM(cur_ev);
			         	if cur_ev[ev] = min(of cur_ev[*]) 
			            then do;
			          		eventIndx=ev; *мне нужен индекс дл€ определени€ событи€;
			          		*MaxValueVar=vname(cur_ev(i));
			         	 	leave;
			     		end; 
					end;
					/*----------------*/

					select (event[cell_i]);
							when (0);
							*инициализаци€;
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
							liveCells+1;
						end;
				end;
				
				/*блок рссчета показателей дл€ вытакивани€ в конечный вектор-саммари*/
				CumMaxTime + max(of time[*]); 

				*  оличество делений = тому, что в следующей строке;
				*  оличество клеток = &cell_N;
				* ¬рем€ жизни попул€ции = CumMaxTime;
				* количество актов делени€ = i ;
				* »сход (вымирание, экспонента) = ColonyStatus;
				*  оличество клеток на выходе (живых) = liveCells;
				*  оличество смертей/выходов -- продукци€ = &cell_N - liveCells  т.е. вычисл€емый параметр;
				
				/**/
				if max(of cell[*]) = . then ColonyStatus = 1; *индикатор вымирани€ колонии, если он не достигаетс€, то колони€ считаетс€ экспоненциально разросшийс€;
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

		* складываем скал€рные величины в специальный датасет ;
		data tmpStatVector (keep = cell_N i CumMaxTime ColonyStatus liveCells );
			*¬ытаскиваем из последней записи ;
			set colony;
			by dummy;
			if last.dummy;
			cell_N = &cell_N;
		run;

		data result;
			set result tmpStatVector;
			cellDeath = cell_N - liveCells;
		run;


		*прицепл€ем динамику изменени€ состава попул€ции новым столбцом ;

		* динамика делени€ ;
		data tmp;
			set colony (keep = &newCell);
		run;

		data newCells;
			merge newCells tmp;
		run;


		data tmp;
			set colony (keep = &cell_N);
		run;

		data cell_Ns;
			merge cell_Ns tmp;
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
	value event_f 0 = "инициализаци€" 1 = "деление" 2 = "дифференцировка";
	value ColonyStatus 0 = " олони€ жива" 1 = " олони€ вымерла";
run;

*----- подготовка данных -----;

data coef_1;
	array a[*] a1-a4;
	array b[*] b1-b4;
	input a[*] b[*];
	datalines;
	0.21 0.12 0.5 0.24 2.0 2.1 2.2 2.3
	; 
run;

*датасет-болванка дл€ правильной обработки первого вызова;
data newCells;
run;
data result;
run;
data cell_Ns;
run;


 
%colonyIt(20);


proc print data = result;
run;

proc means data = result;
	var cell_N i CumMaxTime ColonyStatus liveCells;
run;

proc print data = newCells;
run;

proc print data = cell_Ns;
run;

