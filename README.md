# Docker Lambda with FFmpeg

Image that (very closely) mimics the live AWS Lambda environment with FFmpeg support.

Based on the wonderful: https://hub.docker.com/r/lambci/lambda/

## Prerequisites

You'll need Docker installed

### Copy over compiled binaries to your Lambda package

```bash
env DOCKER_ID=$(docker create nickdenengelsman/lambda-ffmpeg)
docker cp $DOCKER_ID:/ffmpeg/binaries ../REPLACEME
docker cp $DOCKER_ID:/usr/bin/ffmpeg ../REPLACEME/
docker cp $DOCKER_ID:/usr/bin/ffprobe ../REPLACEME/
docker cp $DOCKER_ID:/node_modules/lwip ../REPLACEME/
docker rm -v $DOCKER_ID
```

### TODO's

- [ ] Make `libx265` compiling work
