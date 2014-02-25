all:
	npm install
	./node_modules/.bin/lsc -c *.ls
	./node_modules/.bin/lsc -c -b log.ls
clean:
	rm *.js
