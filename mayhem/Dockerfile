FROM --platform=linux/amd64 ubuntu:22.04 as builder

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake

COPY . /repo
WORKDIR /repo/build
RUN cmake .. -DSPVGENTWO_BUILD_DISASSEMBLER=TRUE
RUN make -j8

FROM ubuntu:22.04
COPY --from=builder /repo/build/SpvGenTwoDisassembler /
