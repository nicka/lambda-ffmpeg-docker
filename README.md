# Docker Lambda with FFmpeg

Image that (very closely) mimics the live AWS Lambda environment with FFmpeg support.

Based on the wonderful: https://hub.docker.com/r/lambci/lambda/

## Prerequisites

You'll need Docker installed

### Copy over compiled binaries to your Lambda package

```bash
id=$(docker create nicka/lambda-ffmpeg)
docker cp $id:/ffmpeg/binaries ../REPLACEME
docker cp $id:/usr/bin/ffmpeg ../REPLACEME/
docker cp $id:/usr/bin/ffprobe ../REPLACEME/
docker rm -v $id
```

### TODO's

- [ ] Make `libx265` compiling work
