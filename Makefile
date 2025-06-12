.PHONY: dev
dev: build
	docker compose up --wait

.PHONY: build
build:
	docker compose build

.PHONY: test
test:
	# Test image-server tif source -> jpg
	curl -fI http://localhost:8182/iiif/2/515698v2_fig1.tif/full/full/0/default.jpg
	# Test image-server gif source -> jpg
	curl -fI http://localhost:8182/iiif/2/515698v2_ueqn1.gif/full/full/0/default.jpg
	# Test image-server tif source -> png
	curl -fI http://localhost:8182/iiif/2/515698v2_fig1.tif/full/full/0/default.png
	# Test image-server gif source -> png
	curl -fI http://localhost:8182/iiif/2/515698v2_ueqn1.gif/full/full/0/default.png

cantaloupe-src:
	git clone git@github.com:cantaloupe-project/cantaloupe.git cantaloupe-src
