SRC != ls *[!input].asm
OBJ = $(SRC:.asm=.o)
BIN = $(OBJ:.o=)

.SUFFIXES: .asm .o

all: $(OBJ)

.asm.o:
	nasm -felf64 -o $@ $<
	$(CC) -o $(@:.o=) $@
	rm -f $@

clean:
	rm -f $(BIN) $(OBJ)
