# Enhanced Preprints Image Server

This project contains the files needed to build a docker image of the
[Cantaloupe image server](https://cantaloupe-project.github.io/) with additional testing and patches

## Prerequisites

- docker

## Building the docker image

Run `docker compose build`

## Running the docker image

Run `docker compose up --wait` and visit http://localhost:8182/

## Docker compose for development

Run `docker compose up --wait`

Visit: http://localhost:8182/

Sample images:

- http://localhost:8182/iiif/2/515698v2_fig1.tif/full/full/0/default.jpg
- http://localhost:8182/iiif/2/96357_elife-96357-fig2-figsupp1-v1.tif/full/full/0/default.jpg
- http://localhost:8182/iiif/2/103047_elife-103047-fig1-figsupp2-v1.tif/full/full/0/default.jpg

## Published Image Versions

Merges to master build and publish new images to Github Container Repository at ghcr.io/elifesciences/cantaloupe

They are tagged with TrunkVer, and appended with the cantaloupe server version in the semver build info (after the +)
