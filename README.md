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

### Test object within Lambda like environment

Be sure to create a `.env.aws` file.

```
docker run --env-file .env.aws  nickdenengelsman/lambda-ffmpeg (samples|tracks|revisions) 07cdf0c8-bed0-4531-bafb-703b74410ac5 (aac|wav|m4a|ogg|mp3)
```

### TODO's

- [ ] Make `libx265` compiling work
