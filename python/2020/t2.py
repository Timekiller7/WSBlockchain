'''
Найдите минимальное натуральное значение nonce, такое, чтобы хэш блока заканчивался четырьмя нулями.
Блок данных представлен в формате json в файле Task2-block.json.
Хэш считается по алгоритму SHA-256, nonce будет являться новым полем блока при его генерации.
В качестве ответа укажите значение nonce и хэш-значение, полученное от данного блока.

Итоговый вид файла:
{
    	"index":1,
"pre_hash":"377d53623993a51bd9d4b2a51247362ef657cb50e1d863ba392db97ed3bf0000",
    	"data":{
        "from":"Bob",
        "to":"Alice",
        "value":100
    	},
    	"nonce":_____,
"hash":"_____"
}
'''

import json
import hashlib
 


with open('C:/Users/daimonion/OneDrive/Документы/BonchSkills/2020/t2.json') as f:
    d = json.load(f)
    stringDataJson = json.dumps(d['data'], separators=(',', ':'))
    
    d['data'] = stringDataJson
    stringWholeJson = json.dumps(d, separators=(',', ':'))

    sha256 = hashlib.sha256()
    sha256.update(stringWholeJson.encode("utf-8"))

    blockHash = sha256.hexdigest()
    blockHash = 476f1d6c34092082ef71c5f26510e5debc28c34f02611b2eec3f17e2cec4c8a2


    sha256 = hashlib.sha256()
    nonce = 1
    blockHash = (sha256.update(blockHash+nonce)).hexdigest()


    while blockHash[-4:0] != "0000":
        nonce += 1
        sha256 = hashlib.sha256()
        blockHash = (sha256.update(blockHash+nonce)).hexdigest()
    print("Nonce: ", nonce)
    print("Block hash: ", blockHash)


