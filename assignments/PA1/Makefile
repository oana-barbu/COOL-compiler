CC=gcc
CFLAGS=-g

.c.o:
	${CC} ${CFLAGS} -c $<

compile: stack.s

stack.s: stack.cl atoi.cl list.cl
	coolc stack.cl atoi.cl list.cl

test:	compile
	@echo stack.test
	spim -file stack.s < stack.test

clean :
	rm -f *.s *~
