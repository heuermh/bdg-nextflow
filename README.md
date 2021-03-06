# bdg-nextflow
Workflows implemented via Nextflow.

### Hacking bdg-nextflow

Install

 * JDK 1.8 or later, http://openjdk.java.net
 * Nextflow version 0.16.1 or later, http://nextflow.io

```bash
$ curl -fsSL get.nextflow.io | bash

  N E X T F L O W
  Version 0.20.1 build 3853
  last modified 18-06-2016 07:00 UTC (03:00 EDT)
  http://nextflow.io

Nextflow installation completed.
```

### transform.nf

Transform all the BAM files found recursively in a given directory to ADAM format.

Run workflow locally (requires ADAM and dependencies to be installed locally)
```bash
$ ./nextflow run transform.nf
N E X T F L O W  ~  version 0.20.1
Launching transform.nf
[warm up] executor > local
[fc/e23ff5] Submitted process > transform (foo)
[1a/7ed6a3] Submitted process > transform (bar)


$ ./nextflow run transform.nf --dir /my/directory/full/of/bam/files
...
```

Run workflow locally using Docker image such as [heuermh/adam](https://registry.hub.docker.com/u/heuermh/adam/) (requires only Docker to be installed locally)
```bash
$ ./nextflow run transform.nf -with-docker heuermh/adam
N E X T F L O W  ~  version 0.20.1
Launching transform.nf
[warm up] executor > local
[89/75c6ac] Submitted process > transform (foo)
[f9/5bd7a8] Submitted process > transform (bar)
```


Use [SLURM](https://computing.llnl.gov/linux/slurm/) executor, with or without Docker
```bash
$ echo "process.executor = 'slurm'" > nextflow.config
$ ./nextflow run transform.nf
N E X T F L O W  ~  version 0.20.1
Launching transform.nf
[warm up] executor > slurm
[f2/ba2eac] Submitted process > transform (bar)
[6a/40187f] Submitted process > transform (foo)
```
