# Найденные ошибки:
1. После сброса сигнал empty_o держится на низком логическом уровне,
Данная ошибка обнаруживается со следующим сообщением:

`Error: Empty error
Time: 25 ps  Scope: top_tb.Monitor.check File: top_tb.sv Line: 401`

2. Ошибка флага almost_full_o, согласно заданию флаг должен подниматься, когда число слов в очереди будет первышать значение параметра ALMOST_FULL,
в тесте он поднимается, когда в очереди ALMOST_FULL свободных мест, сообщение об ошибке:

`Error: Almost full error
Time: 75 ps  Scope: top_tb.Monitor.check File: top_tb.sv Line: 416`

3. Usedw_o реагирует на запись в полную очередь и выходит за пределы адресного пространства:

`Error: Usedw error, usedw:257, ref_ptr:        256
Time: 2635 ps  Scope: top_tb.Monitor.check File: top_tb.sv Line: 396`

4. Сигнал full не появляется после записи последнего слова в очередь, если за такт до него был сигнал read, текст:

`Error: Full error
Time: 2625 ps  Scope: top_tb.Monitor.check File: top_tb.sv Line: 406`

5. Цикла одновременного чтения и записи в заполненную очередь выводятся неправильные значения, данная ошибка повторяется при дальнейшем опустошении очереди. Текст ошибки:

`Error: Wrong read
Time: 10325 ps  Scope: top_tb.Monitor.check File: top_tb.sv Line: 423
expected value:30389, real value:31332, index:        254`

6. Очередь никак не реагирует на одновременную подачу запросов чтения и записи в пустую очередь (ни на запрос чтения ни на запрос записи) и выводит неправильное текущее количество слов и не выводит данные q:

`Error: Usedw error, usedw:  0, ref_ptr:          1
Time: 53895 ps  Scope: top_tb.Monitor.check File: top_tb.sv Line: 396`

`Error: Wrong read
Time: 53905 ps  Scope: top_tb.Monitor.check File: top_tb.sv Line: 423
expected value:21555, real value:20899, index:          1`

7. При попытке чтения из пустой очереди после сброса, сигнал usedw реагирует на запрос и меняется с переполнением, сообщение:

`Error: Usedw error, usedw:511, ref_ptr:          0
Time: 61635 ps  Scope: top_tb.Monitor.check File: top_tb.sv Line: 396`

8. Сигнал almost_full поднимается, хотя не должен, сообщение об ошибке:

`Error: Almost full error
Time: 61655 ps  Scope: top_tb.Monitor.check File: top_tb.sv Line: 418`

9. Сигнал almost_empty поднимается, хотя не должен:

`Error: Almost empty error
Time: 7755 ps  Scope: top_tb.Monitor.check File: top_tb.sv Line: 412`