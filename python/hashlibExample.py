import sys
import hashlib

print(hashlib.sha256(b"Nobody inspects the spammish repetition").hexdigest())
print(hashlib.algorithms_available)

 
def stringHash(string):
    # Initialize
    sha256 = hashlib.sha256()
 
    # Pass byte stream as an argument
    sha256.update(string)
    return sha256.hexdigest()


def hashfile(file):
    BUF_SIZE = 65536
    sha256 = hashlib.sha256()

    with open(file, 'rb') as f:
        while True:
            # reading data = BUF_SIZE from the
            # file and saving it in a variable
            data = f.read(BUF_SIZE)   # fixed buffer size, in bytes
 
            if not data:              # True if eof
                break

            # pass data sha256 func
            sha256.update(data)

            # Acts as a finalize method, after which
            # all the input data gets hashed
    return sha256.hexdigest()
    

# string stored as a byte stream (prefix 'b')
string = b"bonch"

# 1. String hash
print("String hash:", stringHash(string))


# 2. File hash
# To run: python t1.py "test.txt"
print("File hash:", hashfile(sys.argv[1]))

