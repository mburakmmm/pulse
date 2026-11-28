# W3C propagation test vectors

The TSV files adapt a subset of W3C examples and conformance test inputs.
The expected columns assert Pulse's parser or carrier behavior.
`!` denotes a rejected field.

- `traceparent.tsv` covers version handling and HTTP whitespace from the
  [W3C trace-context harness](https://github.com/w3c/trace-context/blob/5ddf6db865590c84ff85d40a582d8216315a1d68/test/test.py).
- `tracestate.tsv` covers vendor ordering and duplicate keys from the
  [Trace Context Recommendation](https://www.w3.org/TR/2021/REC-trace-context-1-20211123/#tracestate-header).
- `baggage.tsv` covers the [Baggage Candidate Recommendation Snapshot examples](https://www.w3.org/TR/2024/CR-baggage-20240530/#examples-of-http-headers)
  and a property case from the [W3C test suite](https://github.com/w3c/baggage/blob/0f167769a4240dd250c71e09187955e7acee9119/test/test_baggage.py).

Run `noxc test --backend <qbe|llvm> tests/unit/w3c_fixtures_test.nox` from
the repository root. CI runs the adapted vectors on both backends.
