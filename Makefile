# Define a variable to hold a comma
comma := ,

assert_OK = (if curl -fI $1; then echo "PASS"; echo ""; else exit 1; fi)
assert_FAIL = (if curl -fI $1; then exit 1; else echo "expected fail"; echo ""; fi)
assert_CONTAINS = (if (curl -fsi $1 | grep $2); then echo "PASS"; echo ""; else exit 1; fi)
assert_NOT_CONTAINS = (if (curl -fsi $1 | grep $2); then exit 1; else echo "PASS"; echo ""; fi)

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
	# Test rescale tif source -> jpg
	$(call assert_OK,http://localhost:8182/iiif/2/96357_elife-96357-fig2-figsupp1-v1.tif/full/200$(comma)/0/default.jpg)
	# Test rescale tif source -> jpg
	$(call assert_OK,http://localhost:8182/iiif/2/103047_elife-103047-fig1-figsupp2-v1.tif/full/200$(comma)/0/default.jpg)

	# Test caddy proxy allowed paths
	$(call assert_OK,http://localhost:8080/test-source/test-prefix/515698v2_fig1.tif/full/full/0/default.jpg)
	$(call assert_OK,http://localhost:8080/test-source:test-prefix/515698v2_fig1.tif/full/full/0/default.jpg)
	$(call assert_OK,http://localhost:8080/test-source:test-prefix%2F515698v2_fig1.tif/full/full/0/default.jpg)

	# Test caddy return body fix
	$(call assert_OK,http://localhost:8080/test-source:test-prefix%2F515698v2_fig1.tif/info.json)
	# Test caddy body contains context.json
	$(call assert_CONTAINS,http://localhost:8080/test-source:test-prefix%2F515698v2_fig1.tif/info.json,context.json)
	# Test caddy does not contain /iiif/2
	$(call assert_NOT_CONTAINS,http://localhost:8080/test-source:test-prefix%2F515698v2_fig1.tif/info.json,iiif/2)

cantaloupe-src:
	git clone git@github.com:cantaloupe-project/cantaloupe.git cantaloupe-src
