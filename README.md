# Docker Nginx Image for HTTPS Proxy

Docker Nginx Image for HTTPS Proxy

## Getting Started

### Prerequisites

* [Docker](https://docs.docker.com/engine/install/) - To run images
* [Docker Compose](https://docs.docker.com/compose/install/) (optional) - For easier usability

#### Quick Guide on macOS

```shell
brew install docker
# or for Docker Desktop
brew install --cask docker
```

### Usage with Docker

Example of how to add HTTPS to a bare Nginx image using only HTTP.

```shell
docker run --rm -d --name http nginx
docker run --rm -d --name https --link http -e WAIT_FOR=http:80 -e UPSTREAM_SERVER=http:80 -v $(pwd)/certificates:/data/conf/nginx/certificates -p 8443:443 iwfwebsolutions/nginx-https-proxy:latest
```

The service should now be accessible over [https://localhost:8443](https://localhost:8443)

### Usage with Docker Compose

Example of how to add HTTPS to a bare Nginx image using only HTTP.

`docker/run/docker-compose.yml(.dist)`

```yaml
services:
  http:
    image: nginx
    init: true
  https:
    image: iwfwebsolutions/nginx-https-proxy:latest
    init: true
    links:
      - http
    environment:
      WAIT_FOR: http:80
      UPSTREAM_SERVER: http:80
    volumes:
      - ./certificates:/data/conf/nginx/certificates
    ports:
      - '8443:443'
```

```shell
docker compose up -d
```

The service should now be accessible over [https://localhost:8443](https://localhost:8443)

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
