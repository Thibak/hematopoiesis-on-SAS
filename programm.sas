

*----- подготовка переменных -----;
proc format;
	value event_f 0 = "инициализация" 1 = "деление" 2 = "смерть";
run;

*----- подготовка данных -----;

data coef_1;
	array a[*] a1-a4;
	array b[*] b1-b4;
	input a[*] b[*];
	datalines;
	0.21 0.02 0.5 0.24 2.0 2.1 2.2 2.3
	; 
run;



%let N = 10;

data colony;
	set coef_1;
	array a[*] a1-a4;
	array b[*] b1-b4;

	array  cell[&N] (0);
	array  time[&N] (0);
	array event[&N] (0);

	array cur_ev[2];
	cell_N = 1;
	newCell = 0;

	do i = 1 to &N; *итератор записей (т.е. циклов деления);
		cell_N + newCell; *прибавляем новые клетки из предыдущей итерации;
		if cell_N > &N then leave;
		newCell = 0; *обнуляем счетчик новых клеток;
		*put cell_N '<=====================';
		do cell_i = 1 to cell_N; *пробегаем по всем клеткам;
		
							/*вот тут мы имеем реальную проблему связанную с тем, 
							что вызов реально происходит только по завершению текущего датастепа,
							реального прерывания не происходит
							надо посоветоваться с аксакалами на счет того, как бы лучше организовать селектор события.
							Есть подозрения, что экзекьют в основном предназначен не для получения данных, а для их занесения
							Можно не запускать макрос, а прямо в теле сделать селектор через временный массив. 
							Вопрос как хранить пары.... Хотя пары нормально в двухмерном векторе хранятся.
							*/
			*селектор события;
			do ev = 1 to DIM(cur_ev);
				cur_ev[ev] = rand('WEIB',a[ev],b[ev]); 
			end;
		
			do ev = 1 to DIM(cur_ev);
	         	if cur_ev[ev] = max(of cur_ev[*]) 
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
							newCell+1;
							if cell_N+newCell > &N then leave;
							cell[cell_N+newCell]  = 1;  
							time[cell_N+newCell]  = 0; 
							event[cell_N+newCell] = 0; *создаем новую клетку;
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
					time[cell_i] = max(of cur_ev[*]) ;
				end;
		end;
	output;
	end;
run;


proc print;
run;

