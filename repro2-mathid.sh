#!/bin/bash
# Discriminating test: build mrpt_math TWICE with IDENTICAL build path and
# identical -j. If the two .debug_* still differ, the non-reproducibility is
# inherent GCC debug-info nondeterminism (not path, not parallelism count).
set -e
SDE=1782068382
SRC=/src

build_into() {
  local dir="$1" jobs="$2"
  rm -rf "$dir"; mkdir -p "$dir"
  cp -a "$SRC"/. "$dir"/
  cd "$dir"; rm -rf .git .vscode build log colcon-install
  export SOURCE_DATE_EPOCH=$SDE DEB_BUILD_MAINT_OPTIONS="hardening=+all" LC_ALL=C.UTF-8 LANG=C.UTF-8
  eval "$(dpkg-buildflags --export=sh)"
  colcon build --base-paths modules apps --packages-up-to mrpt_math \
    --install-base "$dir/colcon-install" --parallel-workers "$jobs" \
    --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu \
      -DMRPT_PYTHON_INSTALL_DIR=lib/python3/dist-packages \
      -DMRPT_WITH_KINECT=OFF -DMRPT_AUTODETECT_SIMD=OFF \
      -DCMAKE_INSTALL_RPATH= -DBUILD_TESTING=ON > "$dir/build.log" 2>&1
}

# Same path token /tmp/S, same jobs 3, two sequential builds:
build_into /tmp/S 3
cp /tmp/S/colcon-install/mrpt_math/lib/x86_64-linux-gnu/libmrpt_math.so.3.0.5 /tmp/S1.so
build_into /tmp/S 3
cp /tmp/S/colcon-install/mrpt_math/lib/x86_64-linux-gnu/libmrpt_math.so.3.0.5 /tmp/S2.so

echo "==================== RESULTS (same path /tmp/S, same -j3) ===================="
ls -l /tmp/S1.so /tmp/S2.so
echo "build-id S1: $(readelf -n /tmp/S1.so | awk '/Build ID/{print $3}')"
echo "build-id S2: $(readelf -n /tmp/S2.so | awk '/Build ID/{print $3}')"
for sec in .text .debug_info .debug_loclists .debug_str; do
  objcopy --dump-section $sec=/tmp/qa /tmp/S1.so 2>/dev/null
  objcopy --dump-section $sec=/tmp/qb /tmp/S2.so 2>/dev/null
  cmp -s /tmp/qa /tmp/qb && st=SAME || st=DIFFER
  printf "%-18s S1=%-11s S2=%-11s %s\n" "$sec" "$(stat -c%s /tmp/qa)" "$(stat -c%s /tmp/qb)" "$st"
  rm -f /tmp/qa /tmp/qb
done
echo "============================================================================="
