
# Neuropixel Ephys Spike Sorting Pipeline on Harvard Medical School O2 Cluster

This document outlines the workflow for performing spike sorting on electrophysiological recorded data using Kilosort4.0, Kilosort2.5, or spykingcircus2 method on the O2 Cluster. This pipeline is a derivative of the one available at [Allen Neural Dynamics GitHub](https://github.com/AllenNeuralDynamics/aind-ephys-pipeline)


The analysis consists of several steps, as illustrated in the flowchart:
- Preprocessing
- Spike sorting
- Post-processing
- Visualization

All these steps are executed through the Nextflow workflow tool. While the pipeline can handle various data formats like `aind`, `nwb`, `openephys`, and `SpikeGLX`, this guide will focus specifically on `SpikeGLX` data.

<p align="center">
  <img src="https://raw.githubusercontent.com/KempnerInstitute/ephys-spike-sorting/main/figures/svg/flowchart-ephys-kilosort4.0-spikesorting.svg" width="40%" />
</p>


## Slurm Job Submission

These are are major steps to run the nextflow pipeline on the HMS O2 
Cluster.

1. Log in to the AI cluster
2. Prepare input data
3. Obtain the pipeline and Slurm scripts
4. Edit the scripts and config files
5. Submit the Slurm job
6. Results and visualization
7. Further Analysis

### 1. Connect to the AI Cluster

Connect to the O2 Cluster using the SSH
```
ssh <your username>@o2.hms.harvard.edu
```
Please find more information about ways to connect to the cluster in the [O2 Documentation](https://harvardmed.atlassian.net/wiki/spaces/O2/pages). 

### 2. Preparing Input Data

Begin by transferring your experimental data to the cluster. Ensure each experiment's data, including the recording  and the corresponding meta data, resides in its own dedicated directory. The expected data structure is:

```
data_dir
    ├── 20240805_M100_4W50_g0_t0.imec0.ap.bin
    └── 20240805_M100_4W50_g0_t0.imec0.ap.meta
```
Here the file with the extention `.bin` is the recording  data and the extention `.meta` is the meta data. 

To process multiple datasets concurrently, check the later section on [processing multiple data directories through a wrapper script](https://github.com/KempnerInstitute/ephys-spike-sorting/edit/dmbala-multi-job/README.md#8-processing-multiple-data-directories-through-a-wrapper-script).

### 3. Copy the Workfow and Job Files

Clone the repository on the cluster. 

```
git clone https://github.com/KempnerInstitute/ephys-spike-sorting 
```

### 4. Edit the Job and Config Files

The relevant job and config files are located in the directory `ephys-spike-sorting/pipeline/hms_cluster`. 

```
cd ephys-spike-sorting/pipeline/hms_cluster
```

Before submitting the job, the Slurm job file `spike_sort.slrm` and the nextflow configuration file `nextflow_slurm.config` need to be edited to specify the relevant directory paths and cluster resources. 

#### 4.a Setting Up Directory Paths

The following environment variables need modification within the `spike_sort.slrm` script:

- **DATA_PATH**: Specifies the location of your input data.
- **WORK_DIR**: A temporary work directory used by the pipeline during execution. e.g. "./scr_tmp_dir"
- **RESULTS_PATH**: Defines where the pipeline will store the generated output files. e.g. "./output"
- **PIPELINE_PATH**: Location of nextflow pipeline and nextflow config files. Usually "./repo_path/pipeline/hms_cluster" or "./"


For testing, you can try the example data with 
```
DATA_PATH="/n/scratch/users/b/bad395/public-data/20240108_M175_4W50_g0_imec0"   
```

#### 4.b Modifying Slurm Job Options

Within the job script, ensure you provide the appropriate partition and time-limit for your job. 

```
#SBATCH --partition=<partition_name>
#SBATCH --time=<time-limit>

```

In addition, change the clusterOptions in **nextflow_slurm.config** 

```
clusterOptions = ' -p <partition_name> --constraint=intel'
```
The nextflow will start all the processes (slurm jobs) in the above parition and account. Without any field in the clusterOptions, the job will utilize the default partition and account. Each process uses the resources set in the file `main_slurm.nf`. The constraint `intel` will restrict the job to run on the intel cpus. 

#### 4.c Environment Setup (optional)

For users running on the HMS O2 cluster, we have cached the containers required for the workflow in a shared directory located at 

The following lines in the Slurm script define the software environment required to run the job: 
```
module load miniconda3/23.1.0
source activate /n/scratch/users/b/bad395/public-data/nextflow_conda 
```
It is okay to use the nextflow package in the above path. Alternatively, the nextflow package can be installed in the local directory. 

### 5. Submitting the Job

Once you've made the necessary adjustments, submit the job script using the sbatch command:

```
sbatch spike_sort.slrm
```

To track the progress of your submitted job, use the squeue command with your username:

```
squeue -u <username>
```

The standard output and pipeline progress will be stored in the Slurm output file `kilosort-<nodename>.<job-name>.<jobid>.out`. Here is a sample Slurm output file showing the progress of the pipeline. 

```
tail ephys-<nodename>.<job-name>.<jobid>.out

[97/6ef142] process > job_dispatch (job-dispatch)    [100%] 1 of 1 ✔
[28/767b98] process > preprocessing (preprocessing)  [100%] 1 of 1 ✔
[-        ] process > spikesort_kilosort25           -
[03/d79c83] process > spikesort_kilosort4 (spikes... [ 50%] 1 of 1
[-        ] process > spikesort_spykingcircus2       -
[-        ] process > postprocessing                 -
[-        ] process > curation                       -
[-        ] process > unit_classifier                -
[-        ] process > visualization                  -
[-        ] process > results_collector              -
[c9/11246a] process > nwb_subject (nwb-subject)      [100%] 1 of 1 ✔
[5c/00d2a3] process > nwb_ecephys (nwb-ecephys)      [100%] 1 of 1 ✔
[-        ] process > nwb_units                      -
```

For the above sample data, the pipeline executed on the O2 Cluster will be completed in 60-120 minutes. 

### 6. Results and Visualization

Upon successful job completion, the output directory will contain various files:

```
curated/               postprocessed/  processing.json  visualization_output.json
data_description.json  preprocessed/   spikesorted/
```


The `visualization_output.json` file provides visualizations of timeseries, drift maps, and the sorting output using Figurl. You can refer to the provided sample visualization for reference.

[sorting_summary](https://figurl.org/f?v=npm://@fi-sci/figurl-sortingview@12/dist&d=sha1://9f1fca96ff81e92a5c0a97e7686b621b925d4efc&label=ecephys_session%20-%20block0_imec0.ap_recording1%20-%20kilosort4%20-%20Sorting%20Summary): spike sorting results for visualization and curation

[timeseries](https://figurl.org/f?v=npm://@fi-sci/figurl-sortingview@12/dist&d=sha1://5f97d47869b7380ff3c4b44df75f738c820e4071&label=ecephys_session%20-%20block0_imec0.ap_recording1): Time series results of sorted spikes. 

#### 6a. Clean Up

The temporary files and copy of the results are stored in the work directory. After copying the results and visualization outputs, you can remove them. 

### 7. Further Analysis and Manual Curation

For manual curation and annotation of your data, you can leverage the Jupyter notebook available as `spike_interface.ipynb` that is available inside the directory postprocess. 

```
postprocess/spike_interface.ipynb
```
### 8. Processing multiple data directories through a wrapper script

The script multijob_submission_wrapper.sh is designed to submit multiple pipelines simultaneously, offering a convenient alternative to manually preparing a Slurm file for each data directory. In the Slurm file spike_sort.slrm, define the environment variable DATA_PATH as the top-level directory. This directory can contain several subdirectories with data files. Below is an example path you can use for testing:

```
DATA_PATH="/n/scratch/users/b/bad395/public-data/Ephys_sample_data"

```
Lets add executable permission to the wrapper script.
```
chmod +x ./multijob_submission_wrapper.sh 
```
Run the script with Slurm file as the argument. 

```
./multijob_submission_wrapper.sh spike_sort.slrm 
```
### 9. Additional Pipeline Arguments

These are the job arguments you can tune for a given job. 
```
job_dispatch_args: 
 --concatenate  
 --input {aind,spikeglx,nwb}

preprocessing_args: 
 --denoising {cmr,destripe} 
 --no-remove-out-channels 
 --no-remove-bad-channels 
 --max-bad-channel-fraction  
 --motion {skip,compute,apply} 
 --motion-preset
```



### Further details on the pipeline and the links to repositories

Electrophysiology analysis pipeline using [Kilosort2.5](https://github.com/MouseLand/Kilosort/tree/v2.5) via [SpikeInterface](https://github.com/SpikeInterface/spikeinterface).

The pipeline is based on [Nextflow](https://www.nextflow.io/) and it includes the following steps:

- [job-dispatch](https://github.com/AllenNeuralDynamics/aind-ephys-job-dispatch/): generates a list of JSON files to be processed in parallel. Parallelization is performed over multiple probes and multiple shanks (e.g., for NP2-4shank probes). The steps from `preprocessing` to `visualization` are run in parallel.
- [preprocessing](https://github.com/AllenNeuralDynamics/aind-ephys-preprocessing/): phase_shift, highpass filter, denoising (bad channel removal + common median reference ("cmr") or highpass spatial filter - "destripe"), and motion estimation (optionally correction)
- [spike sorting](https://github.com/AllenNeuralDynamics/aind-ephys-spikesort-kilosort25/): with Kilosort2.5
- [postprocessing](https://github.com/AllenNeuralDynamics/aind-ephys-postprocessing/): remove duplicate units, compute amplitudes, spike/unit locations, PCA, correlograms, template similarity, template metrics, and quality metrics
- [curation](https://github.com/AllenNeuralDynamics/aind-ephys-curation/): based on ISI violation ratio, presence ratio, and amplitude cutoff
- [unit classification](https://github.com/AllenNeuralDynamics/aind-ephys-unit-classification/): based on pre-trained classifier (noise, MUA, SUA)
- [visualization](https://github.com/AllenNeuralDynamics/aind-ephys-visualization/): timeseries, drift maps, and sorting output in [figurl](https://github.com/flatironinstitute/figurl/blob/main/README.md)
- [result collection](https://github.com/AllenNeuralDynamics/aind-ephys-result-collector/): this step collects the output of all parallel jobs and copies the output folders to the results folder
- export to NWB: creates NWB output files. Each file can contain multiple streams (e.g., probes), but only a continuous chunk of data (such as an Open Ephys experiment+recording or an NWB `ElectricalSeries`). This step includes additional sub-steps:
  - [session and subject](https://github.com/AllenNeuralDynamics/NWB_Packaging_Subject_Capsule)
  - [units](https://github.com/AllenNeuralDynamics/NWB_Packaging_Units)

