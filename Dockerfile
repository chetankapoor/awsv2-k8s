FROM alpine:3.11

ENV GLIBC_VER=2.31-r0

# install glibc compatibility for alpine
RUN apk --no-cache add \
        binutils \
        curl \
    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
    && apk add --no-cache \
        glibc-${GLIBC_VER}.apk \
        glibc-bin-${GLIBC_VER}.apk \
    && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
    && rm -rf \
        awscliv2.zip \
        aws \
        /usr/local/aws-cli/v2/*/dist/aws_completer \
        /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/*/dist/awscli/examples \
    && apk --no-cache del \
        binutils \
        curl \
    && rm glibc-${GLIBC_VER}.apk \
    && rm glibc-bin-${GLIBC_VER}.apk \
    && rm -rf /var/cache/apk/*

    # Ignore to update version here, it is controlled by .travis.yml and build.sh
    # docker build --no-cache --build-arg KUBECTL_VERSION=${tag} --build-arg HELM_VERSION=${helm} --build-arg KUSTOMIZE_VERSION=${kustomize_version} -t ${image}:${tag} .
    ARG HELM_VERSION=3.2.1
    ARG KUBECTL_VERSION=1.17.5
    ARG KUSTOMIZE_VERSION=v3.8.1

    # Install Python3
    RUN apk add --update --no-cache python3 && \
    python3 -m ensurepip && \
    pip3 install --upgrade pip

    # https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
    ARG AWS_IAM_AUTH_VERSION_URL=https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/aws-iam-authenticator

    # Install helm (latest release)
    # ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
    ENV BASE_URL="https://get.helm.sh"
    ENV TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"
    RUN apk add --update --no-cache curl ca-certificates bash git && \
        curl -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
        mv linux-amd64/helm /usr/bin/helm && \
        chmod +x /usr/bin/helm && \
        rm -rf linux-amd64 && \
        apk del curl && \
        rm -f /var/cache/apk/*

    # add helm-diff
    RUN helm plugin install https://github.com/databus23/helm-diff

    # add helm-unittest
    RUN helm plugin install https://github.com/quintush/helm-unittest

    # Install kubectl (same version of aws esk)
    RUN apk add --update --no-cache curl && \
        curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
        mv kubectl /usr/bin/kubectl && \
        chmod +x /usr/bin/kubectl

    # Install kustomize (latest release)
    RUN curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz && \
      tar xvzf kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz && \
      mv kustomize /usr/bin/kustomize && \
      chmod +x /usr/bin/kustomize

    # Install aws-iam-authenticator (latest version)
    RUN curl -LO ${AWS_IAM_AUTH_VERSION_URL} && \
        mv aws-iam-authenticator /usr/bin/aws-iam-authenticator && \
        chmod +x /usr/bin/aws-iam-authenticator

    # Install eksctl (latest version)
    RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
        mv /tmp/eksctl /usr/bin && \
        chmod +x /usr/bin/eksctl

   # Install groff
   RUN apk add groff
