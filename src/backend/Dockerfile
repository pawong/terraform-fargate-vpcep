FROM golang:1.22.2
ARG GIT_COMMIT_HASH
ENV GIT_COMMIT_HASH=${GIT_COMMIT_HASH:-"unknown"}

COPY /api/ /api/
WORKDIR /api/

RUN go build -o main main.go

ENV HOST=0.0.0.0
ENV PORT=80

CMD ["./main"]