# Build notes (Ben Bolker)

These notes document how to build libgourou and its dependencies from source
using CMake on Ubuntu 22.04.

## 1. System packages

```bash
sudo apt install \
    build-essential \
    cmake \
    libssl-dev \
    libcurl4-openssl-dev \
    libzip-dev \
    pkg-config
```

> **Note:** The `libzip-dev` package on Ubuntu 22.04 ships a broken
> `libzip-config.cmake` that references `/usr/bin/zipcmp`, which is not
> installed. The workaround (already applied in `utils/CMakeLists.txt`) is to
> locate libzip via `pkg-config` instead of CMake config mode.

## 2. Clone the repositories

All three repos must be cloned as siblings in the same parent directory.

```bash
# The SamuelMarks forks carry a `cmake` branch with CMake build support.
git clone -b cmake https://github.com/SamuelMarks/updfparser.git
git clone -b cmake https://github.com/SamuelMarks/libgourou.git

# pugixml: use the upstream repo (the cmake branch of libgourou expects it).
git clone https://github.com/zeux/pugixml.git
```

Your directory layout should look like:

```
<parent>/
  libgourou/
  pugixml/
  updfparser/
```

## 3. Build pugixml

pugixml is consumed from its build tree directly (its config file works
without a separate install step).

```bash
cmake -DCMAKE_BUILD_TYPE=Debug \
      -S pugixml \
      -B pugixml/build-cmake

cmake --build pugixml/build-cmake
```

## 4. Build and install updfparser

updfparser must be *installed* to a local prefix before libgourou can find it,
because its `updfparserTargets.cmake` is only generated during install.

```bash
cmake -DCMAKE_BUILD_TYPE=Debug \
      -S updfparser \
      -B updfparser/build-cmake

cmake --build updfparser/build-cmake

cmake --install updfparser/build-cmake \
      --prefix updfparser/install
```

## 5. Configure and build libgourou

Pass both dependency locations via `CMAKE_PREFIX_PATH`.

```bash
cmake -DCMAKE_BUILD_TYPE=Debug \
      -DCMAKE_PREFIX_PATH="$(pwd)/pugixml/build-cmake;$(pwd)/updfparser/install" \
      -S libgourou \
      -B libgourou/build

cmake --build libgourou/build
```

Outputs (`libgourou.a`, `libgourou_utils.a`) are written to `libgourou/build/`.

## Changes made to upstream CMakeLists.txt

`utils/CMakeLists.txt` was modified to work around two issues with the Ubuntu
22.04 system packages:

- `libzip`: changed from `find_package(libzip CONFIG REQUIRED)` to
  `find_package(PkgConfig REQUIRED)` + `pkg_check_modules(libzip ...)`, and
  the link target from `libzip::zip` to `PkgConfig::libzip`.
- `CURL`: changed from `find_package(CURL CONFIG REQUIRED)` to
  `find_package(CURL REQUIRED)` (uses CMake's built-in `FindCURL` module
  instead of the missing system config file).
