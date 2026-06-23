# Build/install notes

These notes document how to build and install `libgourou` and its dependencies
from source using CMake on Ubuntu 22.04 / Pop!\_OS.

## Quick start

Two scripts in this repo handle everything after cloning:

- **`build_all.sh`** — installs missing system packages, clones sibling
  dependencies if needed, and builds everything. Run from the `libgourou/`
  directory:

  ```bash
  bash build_all.sh
  ```

  The default build type is `Release` (optimized, no debug symbols). To
  override — e.g. to add debugging symbols — use:

  ```bash
  BUILD_TYPE=Debug bash build_all.sh
  ```

- **`install.sh`** — installs the libraries, headers, and binaries
  system-wide (default prefix `/usr/local`). Run after `build_all.sh`:

  ```bash
  bash install.sh          # installs to /usr/local (uses sudo)
  PREFIX=~/.local bash install.sh   # or to a custom prefix
  ```

  Installed files:
  - Binaries (`acsmdownloader`, `adept_activate`, `adept_loan_mgt`,
    `adept_remove`, `launcher`) → `$PREFIX/bin/`
  - Static libraries (`libgourou.a`, `libgourou_utils.a`) → `$PREFIX/lib/`
  - Headers → `$PREFIX/include/`
  - CMake config (`libgourouConfig.cmake`) → `$PREFIX/share/libgourou/`

Once you've built and installed, stripping DRM from an ebook you bought and want to read on an open platform is as simple as:

```bash
adept_activate -a ## register anonymously (one-time step)
acsmdownloader -f <my_acsm_file> ## download and decrypt
acsmdownloader --export-private-key ##export key for use with Calibre
adept_remove -f <my_epub_file> ## strip DRM
```

The rest of this file documents the steps the scripts perform, for reference.

---

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

Outputs are written to `libgourou/build/`: static libraries `libgourou.a` and
`libgourou_utils.a`, and executables `acsmdownloader`, `adept_activate`,
`adept_loan_mgt`, `adept_remove`, and `launcher`.

## Changes made to upstream CMakeLists.txt

`utils/CMakeLists.txt` was modified to work around two issues with the Ubuntu
22.04 system packages:

- `libzip`: changed from `find_package(libzip CONFIG REQUIRED)` to
  `find_package(PkgConfig REQUIRED)` + `pkg_check_modules(libzip ...)`, and
  the link target from `libzip::zip` to `PkgConfig::libzip`.
- `CURL`: changed from `find_package(CURL CONFIG REQUIRED)` to
  `find_package(CURL REQUIRED)` (uses CMake's built-in `FindCURL` module
  instead of the missing system config file).
