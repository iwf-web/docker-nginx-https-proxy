# Developer Guide for working on this repository

## Getting Started

### Prerequisites

* [Docker](https://docs.docker.com/engine/install/) - To run images
* [Docker Compose](https://docs.docker.com/compose/install/) - For easier usability
* [Act](https://github.com/nektos/act) - For testing GitHub actions locally
* [jq](https://stedolan.github.io/jq/) - For parsing JSON

#### Quick Guide on macOS

```shell
brew install docker docker-compose
# or for Docker Desktop
brew install --cask docker

brew install act jq gnu-getopt
```

#### Configure environment

We also need a custom builder to build for multiple platforms. Following example calls it `builder-default`.

```shell
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --name builder-default --driver docker-container --bootstrap --use
```

And optionally update submodules with

```shell
git submodule update --remote --merge
```

### Build

Note: Within the `./src/` folder

```shell
docker buildx bake --load
```

### Test

Build step is not required, since Docker Compose can also build the image

Note: Within the `./test/` folder

```shell
docker compose up -d
```

### Test CI

Following will simulate pushing to the branch

Note: At the project root `./`

#### Test Jenkins script

```shell
./.jenkins/ci-cd.sh --branch main --verbose
```

#### Test regular push (Tags: latest, sha-3909bd48)

```shell
act --secret-file ./test/workflows/.secrets.dist
```

#### Test manual dispatch (Tags: latest)

```shell
act workflow_dispatch --secret-file ./test/workflows/.secrets.dist
```

#### Test tag push (Tags: latest, 1.2.3, 1.2, 1)

```shell
act -e ./test/workflows/event-tag.json --secret-file ./test/workflows/.secrets.dist
```

#### Test pull request (Tags: merge)

```shell
act pull_request -e ./test/workflows/event-pr.json --secret-file ./test/workflows/.secrets.dist
```

### Publish

If you want to check the build, run the following commands

Note: Within the `./src/` folder

```shell
LABEL_CREATED=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
LABEL_VERSION=main \
LABEL_REVISION=$(git rev-parse HEAD) \
LABEL_BASE_DIGEST=$(docker images --digests iwfwebsolutions/nginx:1.22-latest --format '{{.Digest}}' | sed s/^\<none\>//) \
TAG2=1.0.0 \
docker buildx bake build --set '*.platform=linux/amd64' --load
```

To check the created tags:

```shell
docker images iwfwebsolutions/nginx-https-proxy
```

To check the created labels:

```shell
docker image inspect iwfwebsolutions/nginx-https-proxy:latest -f '{{ .Config.Labels }}'
# or
docker image inspect iwfwebsolutions/nginx-https-proxy:latest | jq -r '.[0].Config.Labels'
```

and then to actually publish

```shell
LABEL_CREATED=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
LABEL_VERSION=main \
LABEL_REVISION=$(git rev-parse HEAD) \
LABEL_BASE_DIGEST=$(docker images --digests iwfwebsolutions/nginx:1.22-latest --format '{{.Digest}}' | sed s/^\<none\>//) \
TAG2=1.0.0 \
docker buildx bake build --push
```

## Contributing

Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details on our code of conduct, and [CONTRIBUTING.md](CONTRIBUTING.md) for the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository][gh-tags].

## Authors

All the authors can be seen in the [AUTHORS.md](AUTHORS.md) file.

Contributors can be seen in the [CONTRIBUTORS.md](CONTRIBUTORS.md) file.

See also the full list of [contributors][gh-contributors] who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details

## Acknowledgments

A list of used libraries and code with their licenses can be seen in the [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md) file.

[gh-tags]: https://github.com/iwf-web/nginx-https-proxy/tags
[gh-contributors]: https://github.com/iwf-web/nginx-https-proxy/contributors
