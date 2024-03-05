# Найденные ошибки:
1. После сброса сигнал empty_o держится на низком логическом уровне,
Данная ошибка обнаруживается со следующим сообщением:

`Error: time:                  25, error type:Empty error
Time: 25 ps  Scope: top_tb.Monitor.raise_error File: top_tb.sv Line: 400`\

2. Ошибка флага almost_full_o, согласно заданию флаг должен подниматься, когда число слов в очереди будет первышать значение параметра ALMOST_FULL,
в тесте он поднимается, когда в очереди ALMOST_FULL свободных мест, сообщение об ошибке:

`Error: time:                  45, error type:Almost full error
Time: 45 ps  Scope: top_tb.Monitor.raise_error File: top_tb.sv Line: 443`

3. Usedw_o реагирует на запись в полную очередь и выходит за пределы адресного пространства:

`Error: time:                2605, error type:Usedw error
Time: 2605 ps  Scope: top_tb.Monitor.raise_error File: top_tb.sv Line: 443`

### Следующие четыре ошибки взаимосвязаны, веорятно происходит переполнение адреса записи и старые значения затираются
4. Сигнал full не появляется после записи последнего слова в очередь, если за такт до него был сигнал read, текст:

`Error: time:                2605, error type:Usedw error
Time: 2605 ps  Scope: top_tb.Monitor.raise_error File: top_tb.sv Line: 443`

5. Предыдущая ошибка проявляет себя, после начала опустошения очереди, после того как очередь была заполнена и начался цикл, в котором значения записывались и сразу считывались: то есть очередь держалась без свободных мест, программа начала считывать значения, которые по идее не должны были сохраниться в очереди. Текст ошибки:

`Error: time:                7175, error type:Wrong read
Time: 7175 ps  Scope: top_tb.Monitor.raise_error File: top_tb.sv Line: 443'
'expected value:22254, real value:58903, index:        254`

6. /7 Очередь не опустошается, когда должна:

`Error: time:               12215, error type:Almost empty error
Time: 12215 ps  Scope: top_tb.Monitor.raise_error File: top_tb.sv Line: 443`

`Error: time:               12255, error type:Empty error
Time: 12255 ps  Scope: top_tb.Monitor.raise_error File: top_tb.sv Line: 443`
