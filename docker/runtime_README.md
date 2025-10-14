# Runtime Docker Image for FireANTs

The `runtime.dockerfile` creates a smaller Docker image for running FireANTs. It does not
include the full CUDA development toolkit, nor does it use an editable install of
FireANTs. Consequentlly, it may be less convenient for developers, but it is about half
the size of the full image.

Building instructions are similar to the full image.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) (for GPU support)

## Building the Docker Image

First, clone the repository:

```bash
git clone https://github.com/rohitrango/fireants
cd fireants
```

Then, from the root directory of the project, run:

```bash
docker buildx build -t fireants:latest -f docker/runtime.dockerfile .
```

## Running the Container

To run the container with GPU support:

```bash
docker run --gpus all --shm-size=40g -it -v /data:/data fireants:latest
```

## Apptainer usage

```bash
apptainer build fireants-latest.sif docker-daemon://fireants:latest
apptainer run --containall --nv --bind /data:/data fireants-latest.sif
```

## Development with mounted code

To test changes to the fireants python code, you can mount the code directory into the container:

```bash
docker run --gpus all --shm-size=40g -it \
    -v $(pwd)/fireants:/opt/conda/envs/fireants/lib/python3.9/site-packages \
    -v /data:/data fireants:latest
```

This only mounts the fireants package itself, changes to the fused_ops will require a
rebuild of the image.