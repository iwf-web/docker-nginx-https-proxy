variable "REPO" {
    default = "iwfwebsolutions/nginx-https-proxy"
}

variable "TAG" {
    default = "latest"
}
variable "TAG2" {
    default = ""
}

variable "LABEL_CREATED" {
    default = ""
}
variable "LABEL_AUTHORS" {
    default = "IWF Web Solutions Developer <developer@iwf.ch>"
}
variable "LABEL_URL" {
    default = "https://github.com/iwf-web/docker-nginx-https-proxy"
}
variable "LABEL_DOCUMENTATION" {
    default = "${LABEL_URL}"
}
variable "LABEL_SOURCE" {
    default = "git@github.com:iwf-web/docker-nginx-https-proxy.git"
}
variable "LABEL_VERSION" {
    default = ""
}
variable "LABEL_REVISION" {
    default = ""
}
variable "LABEL_VENDOR" {
    default = "IWF Web Solutions"
}
variable "LABEL_LICENSES" {
    # https://spdx.org/licenses/
    default = "MIT"
}
variable "LABEL_REF_NAME" {
    default = "iwfwebsolutions/nginx"
}
variable "LABEL_TITLE" {
    default = "Docker Nginx Image for HTTPS Proxy"
}
variable "LABEL_DESCRIPTION" {
    default = "Docker Nginx Image for HTTPS Proxy"
}
variable "LABEL_BASE_DIGEST" {
    default = ""
}
variable "LABEL_BASE_NAME" {
    default = "docker.io/${LABEL_REF_NAME}:1.22-latest"
}

group "default" {
    targets = ["dev"]
}

target "docker-metadata-action" {}

target "base" {
    dockerfile = "Dockerfile"
    cache-from = ["type=local,src=../.buildx-cache"]
    cache-to = ["type=local,dest=../.buildx-cache"]
}

target "dev" {
    inherits = ["base"]
    tags = ["${REPO}:local"]
}

target "build-ci" {
    inherits = ["base", "docker-metadata-action"]
    platforms = [
        "linux/amd64",
        "linux/arm64"
    ]
}
target "build" {
    inherits = ["build-ci"]
    tags = [
      notequal("", TAG) ? "docker.io/${REPO}:${TAG}" : "",
      notequal("", TAG2) ? "docker.io/${REPO}:${TAG2}" : "",
    ]
    # https://github.com/opencontainers/image-spec/blob/master/annotations.md
    labels = {
        "org.opencontainers.image.created" = "${LABEL_CREATED}",
        "org.opencontainers.image.authors" = "${LABEL_AUTHORS}"
        "org.opencontainers.image.url" = "${LABEL_URL}"
        "org.opencontainers.image.documentation" = "${LABEL_DOCUMENTATION}",
        "org.opencontainers.image.source" = "${LABEL_SOURCE}"
        "org.opencontainers.image.version" = "${LABEL_VERSION}"
        "org.opencontainers.image.revision" = "${LABEL_REVISION}"
        "org.opencontainers.image.vendor" = "${LABEL_VENDOR}"
        "org.opencontainers.image.licenses" = "${LABEL_LICENSES}"
        "org.opencontainers.image.ref.name" = "${LABEL_REF_NAME}"
        "org.opencontainers.image.title" = "${LABEL_TITLE}"
        "org.opencontainers.image.description" = "${LABEL_DESCRIPTION}"
        "org.opencontainers.image.base.digest" = "${LABEL_BASE_DIGEST}"
        "org.opencontainers.image.base.name" = "${LABEL_BASE_NAME}"
    }
}

