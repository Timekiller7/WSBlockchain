'''
Одним из основных алгоритмов хэширования в блокчейн системах является алгоритм KECCAK. 
С помощью данного алгоритма был получен следующий хэш - 

cae726dab13019b44f4fddc12cbfa31533a32e76c055b36f84824793ef18ba0d, 

который хранится в файле Task3-hash.txt.
Входными данными для хэш-функции являлось значение UNIX-Time без учета дробной доли числа. 
Искомая дата – день в 2020 году, параметры hour = 0, minute = 0, second = 0, microsecond = 0, часовой пояс – UTC. 
В качестве ответа укажите искомые день и месяц, а также полученное значение UNIX-time.
'''


import datetime
import time
import hashlib
from Crypto.Hash import keccak #pycryptodome


txHash = "cae726dab13019b44f4fddc12cbfa31533a32e76c055b36f84824793ef18ba0d"
date = datetime.datetime(2020, 1, 1, 0, 0, 0, 0)
date2 = datetime.datetime(2021, 1, 1, 0, 0, 0, 0)

print(date)

timestamp = int(time.mktime(date.timetuple()))
timestamp2 = int(time.mktime(date2.timetuple()))
print("unix_timestamp => ",
      timestamp)

timestamp *= 1000  # тк милисекунды нужны
timestamp2 *= 1000

#31*7
#30*4
#29

timestamp   #86 400 000 
len = timestamp2-timestamp

keccak_hash = keccak.new(digest_bits=512)
#keccak_hash.update(b'Some data')

for i in range(len):
    if keccak_hash.update(timestamp).hexdigest() == txHash:
        print(timestamp)
        break
    timestamp = timestamp + 86400000 
    








