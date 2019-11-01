# With docker

```bash
# build
docker build -t list-gen .
# run
docker run --rm -it --user=$(id -u):$(id -g) -v $(pwd)/:/gen list-gen /bin/bash
```

# Usage

```bash
./createBarcodeList.sh
# or with joined_at date
./createBarcodeList.sh 2019-01-15
```

```bash
./createPassList.sh
# or with joined_at date
./createPassList.sh 2019-01-15
```
