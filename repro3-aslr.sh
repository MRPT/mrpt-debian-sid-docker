#!/bin/bash
# Hypothesis test: is the run-to-run .debug_info/.debug_loclists nondeterminism
# caused by ASLR-seeded GCC hash ordering? Build mrpt_math TWICE with identical
# path and -j, but wrap the whole build in `setarch -R` (ASLR disabled).
# If the two build-ids now match -> ASLR is the cause and disabling it is the fix.
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
  setarch "$(uname -m)" -R \
  colcon build --base-paths modules apps --packages-up-to mrpt_math \
    --install-base "$dir/colcon-install" --parallel-workers "$jobs" \
    --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu \
      -DMRPT_PYTHON_INSTALL_DIR=lib/python3/dist-packages \
      -DMRPT_WITH_KINECT=OFF -DMRPT_AUTODETECT_SIMD=OFF \
      -DCMAKE_INSTALL_RPATH= -DBUILD_TESTING=ON > "$dir/build.log" 2>&1
}

build_into /tmp/R 3
cp /tmp/R/colcon-install/mrpt_math/lib/x86_64-linux-gnu/libmrpt_math.so.3.0.5 /tmp/R1.so
build_into /tmp/R 3
cp /tmp/R/colcon-install/mrpt_math/lib/x86_64-linux-gnu/libmrpt_math.so.3.0.5 /tmp/R2.so

echo "==================== RESULTS (setarch -R, same path /tmp/R, same -j3) ===================="
ls -l /tmp/R1.so /tmp/R2.so
echo "build-id R1: $(readelf -n /tmp/R1.so | awk '/Build ID/{print $3}')"
echo "build-id R2: $(readelf -n /tmp/R2.so | awk '/Build ID/{print $3}')"
for sec in .text .debug_info .debug_loclists .debug_str; do
  objcopy --dump-section $sec=/tmp/qa /tmp/R1.so 2>/dev/null
  objcopy --dump-section $sec=/tmp/qb /tmp/R2.so 2>/dev/null
  cmp -s /tmp/qa /tmp/qb && st=SAME || st=DIFFER
  printf "%-18s R1=%-11s R2=%-11s %s\n" "$sec" "$(stat -c%s /tmp/qa)" "$(stat -c%s /tmp/qb)" "$st"
  rm -f /tmp/qa /tmp/qb
done
echo "cmp unstripped: $(cmp -s /tmp/R1.so /tmp/R2.so && echo IDENTICAL || echo DIFFER)"
echo "=========================================================================================="
