from hashlib import sha3_224
import datetime
from datetime import timezone
from web3 import Web3
from Crypto.Hash import keccak


# какой то не тот keccak


# cae726dab13019b44f4fddc12cbfa31533a32e76c055b36f84824793ef18ba0d,
#
# который хранится в файле Task3-hash.txt.
# Входными данными для хэш-функции являлось значение UNIX-Time без учета дробной доли числа.
# Искомая дата – день в 2020 году, параметры hour = 0, minute = 0, second = 0, milisecond = 0, часовой пояс – UTC.
# В качестве ответа укажите искомые день и месяц, а также полученное значение UNIX-time.

date = datetime.datetime(2020, 1, 1, 0, 0, 0,0)
date2 = datetime.datetime(2021, 1, 1, 0, 0, 0,0)



dateTest = datetime.datetime(2020, 7, 4, 0, 0, 0,0)
tTest = int(dateTest.replace(tzinfo=timezone.utc).timestamp())

keccak_hash = keccak.new(digest_bits=256)
stringTime = str(tTest).encode("utf-8")
keccak_hash.update(stringTime)
hashTest = keccak_hash.hexdigest()
print("hash test: ", hashTest)


HASH = "cae726dab13019b44f4fddc12cbfa31533a32e76c055b36f84824793ef18ba0d"
t1 = int(date.replace(tzinfo=timezone.utc).timestamp())
#print(t1) #тоже 1577836800
t2 = int(date2.replace(tzinfo=timezone.utc).timestamp())



t1 = 1577836800  # кажется этот верный
for i in range(366):
    keccak_hash = keccak.new(digest_bits=256)
    stringTime = str(t1).encode("utf-8")
    keccak_hash.update(stringTime)
    hash = keccak_hash.hexdigest()
    print(t1)
    if hashTest == hash:
        print("rrr", t1)
        break
    t1 += 86400


