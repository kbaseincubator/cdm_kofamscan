# cdm_kofamscan

CTS (CDM Task Service) job wrapper for [KofamScan](https://github.com/takaram/kofam_scan), which assigns KEGG KO annotations to proteins using HMM profiles.

## Container

Wraps the official [BioContainers KofamScan image](https://quay.io/repository/biocontainers/kofamscan?tab=tags).

Published to `ghcr.io/kbaseincubator/cdm_kofamscan`.

**Entrypoint:** `exec_annotation` (no subcommand). Append KofamScan flags as arguments.

**Reference data:** Required. CTS mounts the KEGG profile HMMs and ko_list at `/ref_data/`:
- `/ref_data/profiles/` — directory of `.hmm` files
- `/ref_data/ko_list` — KO definitions

The container reads them via `KOFAM_PROFILES` and `KOFAM_KO_LIST` env vars, but you still pass `-p` and `-k` explicitly in your job args (KofamScan doesn't honor the env vars by itself).

## Usage via CTS

See the demo notebook at `global_share/jplfaria/kofamscan_demo.ipynb` on hub.berdl.kbase.us.

### Example

```python
job = tscli.submit_job(
    "ghcr.io/kbaseincubator/cdm_kofamscan:0.1.0@sha256:<digest>",
    input_files,                       # protein FASTA files
    "cts/io/jplfaria/output/kofamscan/test/v1",
    cluster="kbase",
    declobber=True,
    output_mount_point="/out",
    args=[
        "-p", "/ref_data/profiles",
        "-k", "/ref_data/ko_list",
        "-o", "/out/annotations.tsv",
        "-f", "detail-tsv",
        "--cpu", "8",
        "--tmp-dir", "/out/tmp",
        tscli.insert_files(),
    ],
    num_containers=4,
    cpus=8,
    memory="32GB",
    runtime="PT2H"
)
```

## Output

- `annotations.tsv` — tab-separated table with columns: gene name, KO, threshold, score, e-value, KO definition. Imported to Delta Lake.
