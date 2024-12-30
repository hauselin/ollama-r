# mall

<details>

* Version: 0.1.0
* GitHub: NA
* Source code: https://github.com/cran/mall
* Date/Publication: 2024-10-24 14:30:02 UTC
* Number of recursive dependencies: 49

Run `revdepcheck::revdep_details(, "mall")` for more info

</details>

## Newly broken

*   checking tests ...
    ```
      Running ‘testthat.R’
     ERROR
    Running the tests in ‘tests/testthat.R’ failed.
    Last 13 lines of output:
      Error in `con$status_code`: $ operator is invalid for atomic vectors
      Backtrace:
          ▆
       1. └─mall:::skip_if_no_ollama() at test-llm-verify.R:42:3
       2.   └─mall:::ollama_is_present() at tests/testthat/helper-ollama.R:20:3
      ── Error ('test-zzz-cache.R:2:3'): Ollama cache exists and delete ──────────────
      Error in `con$status_code`: $ operator is invalid for atomic vectors
      Backtrace:
          ▆
       1. └─mall:::skip_if_no_ollama() at test-zzz-cache.R:2:3
       2.   └─mall:::ollama_is_present() at tests/testthat/helper-ollama.R:20:3
      
      [ FAIL 8 | WARN 0 | SKIP 7 | PASS 38 ]
      Error: Test failures
      Execution halted
    ```

