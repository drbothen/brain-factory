# The Practical Guide to Retrieval-Augmented Generation

Retrieval-Augmented Generation (RAG) combines a language model with a retrieval
step that fetches relevant documents from an external store before generating a
response. This grounds the model's output in verified, up-to-date sources rather
than relying solely on weights learned at training time.

## How the Retrieval Step Works

When a query arrives, the system embeds it into a vector space and performs an
approximate nearest-neighbour search against a pre-indexed corpus. The top-k
chunks are prepended to the model's context window alongside the original query,
giving the model accurate factual anchors for its completion.

## Why This Matters for Second-Brain Systems

A personal knowledge base benefits from RAG in two ways: first, it allows the
system to cite the exact source document that informed a synthesis; second, it
keeps the retrieval corpus in sync with the operator's own notes rather than a
static training snapshot. The combination of local-file ingest and vector search
makes the brain both current and attributable.
