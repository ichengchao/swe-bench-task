FROM python:3.9-slim

RUN pip install pytest

WORKDIR /app

# Clone repo and checkout to the buggy commit
RUN apt-get update && apt-get install -y git && \
    git clone https://github.com/ichengchao/swe-bench-test.git /app && \
    git checkout 932468602d3778403ec173ca7a1151d329c9e027 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
