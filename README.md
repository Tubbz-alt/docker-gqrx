# docker-gqrx

## Build
```bash
./buid.sh
```

## Run
```bash
./host_runner.sh ${DOCKER_ID}
```

## Fixed
- when started the gqrx, it crashed with below error:
  ```
  Assertion 'p' failed at pulse/simple.c:273, function pa_simple_write(). Aborting
  ```

## Links
[Docker Hub](https://hub.docker.com/r/thebiggerguy/docker-gqrx/)
