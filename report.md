Найденные ошибки:

### Следующие три ошибки связаны с проблемами сброса :
1. После сброса сигнал empty_o держится на низком логическом уровне,
Данная ошибка обнаруживается со следующим сообщением:

`Error: time:                  25, error type:Empty error
Time: 25 ps  Scope: top_tb.Monitor.raise_error File: top_tb.sv Line: 400`

2. При подаче сигнала rdreq_i после сброса происходит переполнение usedw_o и из значения '0 он переходит в '1. Сообщение:

`Error: time:                 425, error type:Usedw error
Time: 425 ps  Scope: top_tb.Monitor.raise_error File: top_tb.sv Line: 401`

3. Также и сигнал almost_empty_o выводит неправильное значение после ошибки номер 2, и при usedw = 0 выводит низкий логический уровень, текст ошибки:

`Error: time:                 555, error type:Almost empty error
Time: 555 ps  Scope: top_tb.Monitor.raise_error File: top_tb.sv Line: 401`