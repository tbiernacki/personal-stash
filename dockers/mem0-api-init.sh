#!/bin/sh
set -e

pip install --no-cache-dir langchain-neo4j rank-bm25


# Tail logs or keep container alive)
tail -f /dev/null
