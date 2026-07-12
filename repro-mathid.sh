#!/bin/bash
# Reproduce the non-reproducible GNU build-id of libmrpt_math.so.
# Builds "up to mrpt_math" twice, varying build path + parallelism (the two
# things that differed between the salsa build job and the debrebuild), using
# the same dpkg-buildflags and SOURCE_DATE_EPOCH the CI used.
set -e
SDE=1782068382            # SOURCE_DATE_EPOCH used by the CI debrebuild
SRC=/src                  # mounted (read-only) clean checkout

build_one() {
  local dir="$1" jobs="$2"
  rm -rf "$dir"; mkdir -p "$dir"
  cp -a "$SRC"/. "$dir"/
  cd "$dir"
  rm -rf .git .vscode build log colcon-install
  export SOURCE_DATE_EPOCH=$SDE
  export DEB_BUILD_MAINT_OPTIONS="hardening=+all"
  export LC_ALL=C.UTF-8 LANG=C.UTF-8
  eval "$(dpkg-buildflags --export=sh)"
  echo "=== [$dir] CXXFLAGS=$CXXFLAGS"
  colcon build \
    --base-paths modules apps \
    --packages-up-to mrpt_math \
    --install-base "$dir/colcon-install" \
    --parallel-workers "$jobs" \
    --cmake-args \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu \
      -DMRPT_PYTHON_INSTALL_DIR=lib/python3/dist-packages \
      -DMRPT_WITH_KINECT=OFF \
      -DMRPT_AUTODETECT_SIMD=OFF \
      -DCMAKE_INSTALL_RPATH= \
      -DBUILD_TESTING=ON \
    > "$dir/build.log" 2>&1
}

echo "### BUILD A: path /tmp/A  jobs 4"
build_one /tmp/A 4
echo "### BUILD B: path /tmp/B  jobs 2"
build_one /tmp/B 2

LIB=lib/x86_64-linux-gnu/libmrpt_math.so.3.0.5
A=/tmp/A/colcon-install/$LIB
B=/tmp/B/colcon-install/$LIB

echo "==================== RESULTS ===================="
ls -l "$A" "$B"
echo "--- sha1 (unstripped) ---"; sha1sum "$A" "$B"
echo "--- build-id A ---"; readelf --notes "$A" | grep -i 'Build ID'
echo "--- build-id B ---"; readelf --notes "$B" | grep -i 'Build ID'
echo "--- cmp unstripped ---"; cmp "$A" "$B" && echo "UNSTRIPPED IDENTICAL" || echo "UNSTRIPPED DIFFER"

# Now strip both like dh_strip does (noautodbgsym -> discard debug) and compare:
cp "$A" /tmp/A.so; cp "$B" /tmp/B.so
strip --strip-unneeded --remove-section=.comment --remove-section=.note /tmp/A.so 2>/dev/null || strip /tmp/A.so
strip --strip-unneeded --remove-section=.comment --remove-section=.note /tmp/B.so 2>/dev/null || strip /tmp/B.so
echo "--- cmp stripped (build-id note removed) ---"
cmp /tmp/A.so /tmp/B.so && echo "STRIPPED IDENTICAL" || echo "STRIPPED DIFFER"
echo "================================================="
