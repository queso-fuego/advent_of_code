BIN=day1_1 day1_2

all: $(BIN)

day1_1: day1_1.o
	ld -o day1_1 day1_1.o
	rm -f day1_1.o

day1_2: day1_2.o
	ld -o day1_2 day1_2.o
	rm -f day1_2.o

day1_1.o: day1_1.asm
	nasm -felf64 -o day1_1.o day1_1.asm

day1_2.o: day1_2.asm
	nasm -felf64 -o day1_2.o day1_2.asm

clean:
	rm -f $(BIN) *.o
