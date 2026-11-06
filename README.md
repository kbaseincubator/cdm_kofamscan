# cdm_kofamscan

CTS (CDM Task Service) job wrapper for [KofamScan](https://github.com/takaram/kofam_scan), which assigns KEGG KO annotations to proteins using HMM profiles.

## Container

Wraps the official [BioContainers KofamScan image](https://quay.io/repository/biocontainers/kofamscan?tab=tags).

Published to `ghcr.io/kbaseincubator/cdm_kofamscan`.

**Entrypoint:** `exec_annotation` (no subcommand). Append KofamScan flags as arguments.

**Reference data:** Required. CTS mounts the KEGG profile HMMs and ko_list at `/ref_data/`:
- `/ref_data/profiles/`: directory of `.hmm` files
- `/ref_data/ko_list`: KO definitions

The container reads them via `KOFAM_PROFILES` and `KOFAM_KO_LIST` env vars, but you still pass `-p` and `-k` explicitly in your job args (KofamScan doesn't honor the env vars by itself).

## Usage via CTS

See `demo.ipynb` in this repo for an end-to-end run.

### Example

```python
job = tscli.submit_job(
    "ghcr.io/kbaseincubator/cdm_kofamscan:0.1.0@sha256:d6b20eccf4c6bf1b095e530844a8b04dbae5fca85daf0c9b2bdffb0cf10a9a42",
    input_files,                       # protein FASTA files, one per container
    "cts/io/<your_username>/output/kofamscan/run1",
    cluster="kbase",
    declobber=True,
    output_mount_point="/out",
    args=[
        "-p", "/ref_data/profiles",
        "-k", "/ref_data/ko_list",
        "-o", "/out/annotations.tsv",
        "-f", "detail-tsv",
        "--cpu", "4",                  # match cpus
        "--tmp-dir", "/tmp/kofam",     # keep scratch OUTSIDE /out, or it is uploaded with the results
        tscli.insert_files(),
    ],
    num_containers=len(input_files),   # exec_annotation accepts exactly one query file
    cpus=4,
    memory="16GB",
    runtime="PT2H",
)
```

`exec_annotation` takes a single query FASTA. With more files than containers it fails with "Too many arguments", so always set `num_containers=len(input_files)`. With `declobber=True` each container's `annotations.tsv` lands under its own `<output_dir>/<container_number>/`.

## Output

- `annotations.tsv` (`-f detail-tsv`): one row per HMM hit, **7** tab-separated columns:
  `#` (significance flag), gene name, KO, threshold, score, E-value, KO definition.
  The first column is `*` when the score is above the KO's adaptive threshold. **Only `*` rows are KO assignments**; the other rows are sub-threshold hits. Read the file with all 7 columns and count assignments as starred rows only (in a test on one small genome: 2,655 rows, 122 starred).
- Importer into the lakehouse: in progress (kbase/cdm-spark-events-importers PR #42), not yet merged.
