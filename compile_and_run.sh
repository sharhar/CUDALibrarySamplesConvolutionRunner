#! /bin/bash

# ensure $2 is a positive integer
case "$2" in
  ''|*[!0-9]*) echo "Second arg must be a positive integer"; exit 64;;
  0) echo "Repeat count must be >= 1"; exit 64;;
esac

if [ -n "$CUDA_HOME" ]; then
    NVCC="$CUDA_HOME/bin/nvcc"
else
    NVCC="nvcc"
fi

fft_size="$1"
file="../convolution_performance.cu"
line_no=228

if [ ! -f "$file" ]; then
  echo "Error: file '$file' not found" >&2
  exit 2
fi

# use awk to replace exactly line $line_no
tmp="$(mktemp "${file}.tmp.XXXXXX")"
awk -v N="$line_no" -v VAL="$fft_size" \
    'NR==N { printf("static constexpr unsigned int fft_size = %s;\n", VAL); next } { print }' \
    "$file" > "$tmp"

# move into place
mv -- "$tmp" "$file"
echo "Replaced line $line_no in $file"

$NVCC -std=c++17 -O3 \
    -I /home/shaharsandhaus/cutlass/include \
    -I /home/shaharsandhaus/nvidia-mathdx-25.06.1/nvidia/mathdx/25.06/include \
    -gencode arch=compute_86,code=sm_86 \
    -lcufft \
    ../convolution_performance.cu


repeat="$2"

for ((i=1; i<=repeat; i++)); do
  echo ""
  echo ""
  echo "Iteration $i: setting fft_size=$1"
  echo "============================="
  ./a.out
done
