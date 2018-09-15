# Install

Create the docker image with:
```bash
docker build -t sbs-build .
```

# Config

Change the `config.ini` file that everything lays in `/mnt/serial-barcode-scanner` (change every folder...).


# Usage

Run the image with:
```bash
# change into the "serial-barcode-scanner" directory
cd ..

docker run --rm -it -p 8080:8080 -v "$PWD":/mnt/serial-barcode-scanner sbs-build tmux
```

You have now a tmux terminal to work with the vala files and run the program. 

You can now start the single binaries in "obj-x..../src/" dir. 