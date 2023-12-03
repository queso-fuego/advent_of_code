TARGETS = part1 part2

all: $(TARGETS) run

%: %.asm
	fasm.x64 $< $@ 
	@chmod 777 $@
	@printf "\n"

run: 
	@for file in $(TARGETS); do \
		printf "%s:\n" "$$file"; \
		./$$file; \
		printf "\nExit Code: $$?\n\n"; \
	done;

clean:
	rm -f $(TARGETS)
