FROM --platform=linux/amd64 ubuntu:22.04 as builder

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake clang

COPY . /repo
WORKDIR /repo/build
RUN cmake .. -DSPVGENTWO_BUILD_DISASSEMBLER=TRUE
RUN make -j8
RUN clang++ /repo/mayhem/fuzz_stringLength.cpp -fsanitize=fuzzer,address -I /repo/lib/include/spvgentwo/ -std=c++17 -o /fuzz

FROM ubuntu:22.04
COPY --from=builder /repo/build/SpvGenTwoDisassembler /
COPY --from=builder /fuzz /fuzz_stringLength
