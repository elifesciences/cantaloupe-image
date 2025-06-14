# Define a variable to hold a comma
comma := ,

assert_OK = (if curl -fI $1; then echo "PASS"; else exit 1; fi)
assert_FAIL = (if curl -fI $1; then exit 1; else echo "expected fail"; fi)

.PHONY: prod
prod: build
	docker compose up --wait

.PHONY: dev
dev: build-local
	docker compose up --wait

.PHONY: build
build:
	docker compose build

.PHONY: build-local
build-local:
	docker compose build --build-arg BUILD_SOURCE=local

.PHONY: test
test:
	# Test image-server tif source -> jpg
	$(call assert_OK,http://localhost:8182/iiif/2/515698v2_fig1.tif/full/full/0/default.jpg)
	# Test image-server gif source -> jpg
	$(call assert_OK,http://localhost:8182/iiif/2/515698v2_ueqn1.gif/full/full/0/default.jpg)
	# Test image-server tif source -> png
	$(call assert_OK,http://localhost:8182/iiif/2/515698v2_fig1.tif/full/full/0/default.png)
	# Test image-server gif source -> png
	$(call assert_OK,http://localhost:8182/iiif/2/515698v2_ueqn1.gif/full/full/0/default.png)

.PHONY: test-expected-to-fail
test-expected-to-fail:
	# Rescaling this image is causing a 500 error
	$(call assert_FAIL,http://localhost:8182/iiif/2/96357_elife-96357-fig2-figsupp1-v1.tif/full/200$(comma)/0/default.jpg)
	$(call assert_FAIL,http://localhost:8182/iiif/2/103047_elife-103047-fig1-figsupp2-v1.tif/full/200$(comma)/0/default.jpg)

cantaloupe-src:
	git clone git@github.com:cantaloupe-project/cantaloupe.git cantaloupe-src
