import hashlib
import json
'''
Найти хэш-значение транзакции, приведенной в формате json, 
используя алгоритм хэширования MD5. 
В качестве ответа укажите хэш значение в шестнадцатеричной форме. 

{
 "from":"0x08e2408e1697b59d9761448f8172418cc0e18c42",
 "to":"0x591f6a91b450f9a63ab6d885db4e032a5d9c1ef5",
 "value":100
}

c09ce9bfe3c03f618ded7434af501d05

''' 
                             

# md5 
 
with open('C:/Users/daimonion/OneDrive/Документы/BonchSkills/2020/tx.json') as f:
    d = json.load(f)
    stringJson = json.dumps(d, separators=(',', ':'))
    print("Dumps: ", stringJson)  # чтобы без пробелов
    stringEncoded = stringJson.encode("utf-8")
    md5 = hashlib.md5()
    md5.update(stringEncoded)
    print("Result: ", md5.hexdigest())

f.close()