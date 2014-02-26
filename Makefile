SUB_LS_DIRS = robot
export LSC = $(shell pwd)/node_modules/.bin/lsc

all: lsc-sub
	npm install
	$(LSC) -c *.ls
	$(LSC) -c -b log.ls

lsc-sub:
	@for i in $(SUB_LS_DIRS); do \
		$(MAKE) -C $$i $(MFLAGS) lsc; done

clean:
	rm *.js
	@for i in $(SUB_LS_DIRS); do \
		$(MAKE) -C $$i $(MFLAGS) clean; done

