
# Neuropixel Ephys Spike Sorting Pipeline on Kempner AI Cluster

This document outlines the workflow for performing spike sorting on electrophysiological recorded data using Kilosort4.0, Kilosort2.5, or spykingcircus2  method on Kempner AI cluster. Please refer [HMS Cluster](HMS-cluster/README.md) if you plan to use Harvard Medical School's O2 Cluster.  This pipeline is a derivative of the one available at [Allen Neural Dynamics GitHub](https://github.com/AllenNeuralDynamics/aind-ephys-pipeline).

To run the analysis on Kempner AI Cluster, please refer to [HMS Cluster](HMS-cluster/README.md). 

To run the analysis on Harvard Medical School's O2 Cluster, please refer to [HMS Cluster](HMS-cluster/README.md).  

The analysis consists of several steps, as illustrated in the flowchart:
- Preprocessing
- Spike sorting
- Post-processing
- Visualization

All these steps are executed through the Nextflow workflow tool. While the pipeline can handle various data formats like `aind`, `nwb`, `openephys`, and `SpikeGLX`, this guide will focus specifically on `SpikeGLX` data.

<p align="center">
  <img src="https://github.com/KempnerInstitute/ephys-spike-sorting/blob/update-fig/figures/svg/flowchart-ephys-kilosort4.0-spikesorting.svg" width="60%" />
</p>

