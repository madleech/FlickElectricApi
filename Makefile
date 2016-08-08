PATH := ./node_modules/.bin:${PATH}

.PHONY : init build dist publish

init:
	npm install

clean:
	rm -rf lib/

build:
	coffee -o lib/ -c src/

dist: clean init build

publish: dist
	npm publish
