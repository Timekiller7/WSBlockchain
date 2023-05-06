import hashlib

F="Бутерин"

w=b"SFedU_Championship2021"
sha224 = hashlib.sha224()
sha224.update(w)
W = sha224.hexdigest()
print(W)

SUM="13e656d84ccd2bed5446de7dda9741049f6086c465dd7e80b8271649"
for X in range(1,100000):
    word = (W+F+str(X)).encode('utf-8')
    sha3_256 = hashlib.sha3_256()
    sha3_224 = hashlib.sha3_224()
    sha3_384 = hashlib.sha3_384()
    sha3_512 = hashlib.sha3_512()

    sha3_256.update(word)
    sha3_224.update(word)
    sha3_384.update(word)
    sha3_512.update(word)

    if sha3_256.hexdigest() == SUM:
        print(256)
        print(X)
        break
    if sha3_224.hexdigest() == SUM:
        print(224)
        print(X)
        break
    if sha3_384.hexdigest() == SUM:
        print(384)
        print(X)
        break
    if sha3_512.hexdigest() == SUM:
        print(512)
        print(X)
        break

  

#print(hashlib.algorithms_available)