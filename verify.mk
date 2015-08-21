all: $(addprefix test,$(shell seq 1 100))

%:
	@echo "Executing $@ on host `hostname`"
	@sleep 5
