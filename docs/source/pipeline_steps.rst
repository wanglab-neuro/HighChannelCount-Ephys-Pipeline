.. _pipeline_steps:

Pipeline Steps
==============

The AIND Ephys Pipeline consists of several key processing steps that are executed in sequence. Here's a detailed look at each step:

Job Dispatch
------------

The `job-dispatch <https://github.com/AllenNeuralDynamics/aind-ephys-job-dispatch/>`_ step:

* Generates JSON files for parallel processing
* Enables parallelization across:
   * Multiple probes
   * Multiple shanks (e.g., for NP2-4shank probes)
* Creates independent processing jobs for parallel execution

Preprocessing
-------------

The `preprocessing <https://github.com/AllenNeuralDynamics/aind-ephys-preprocessing/>`_ step handles several critical data preparation tasks:

* Phase shift correction
* Highpass filtering
* Denoising
   * Bad channel removal
   * Common median reference ("cmr") or highpass spatial filter ("destripe")
* Motion estimation and correction (optional)

Spike Sorting
-------------

The pipeline supports multiple spike sorting algorithms:

* `Kilosort2.5 <https://github.com/AllenNeuralDynamics/aind-ephys-spikesort-kilosort25/>`_
* `Kilosort4 <https://github.com/AllenNeuralDynamics/aind-ephys-spikesort-kilosort4/>`_
* `SpykingCircus2 <https://github.com/AllenNeuralDynamics/aind-ephys-spikesort-spykingcircus2/>`_

Each sorter can be selected based on your specific needs and data characteristics.

Postprocessing
--------------

The `postprocessing <https://github.com/AllenNeuralDynamics/aind-ephys-postprocessing/>`_ step performs extensive analysis:

* Duplicate unit removal
* Amplitude computations
* Spike/unit location analysis
* Principal Component Analysis (PCA)
* Correlograms
* Template similarity
* Template metrics
* Quality metrics calculation

Curation
--------

The `curation <https://github.com/AllenNeuralDynamics/aind-ephys-curation/>`_ step applies quality control:

* Quality metrics-based filtering:
   * ISI violation ratio
   * Presence ratio
   * Amplitude cutoff
* Unit classification as noise, MUA, or SUA using pretrained classifier (UnitRefine)

Visualization
-------------

The `visualization <https://github.com/AllenNeuralDynamics/aind-ephys-visualization/>`_ step generates:

* Timeseries visualizations
* Drift maps
* Sorting output using `Figurl <https://github.com/flatironinstitute/figurl/>`_
* Interactive plots for data exploration

Result Collection
-----------------

The `result collection <https://github.com/AllenNeuralDynamics/aind-ephys-result-collector/>`_ step:

* Aggregates outputs from all parallel jobs
* Copies output folders to the results directory
* Organizes results in a standardized structure

NWB Export
----------

The final step creates standardized NWB output files, including:

* Session and subject information from `aind-subject-nwb <https://github.com/AllenNeuralDynamics/aind-subject-nwb>`_
* Ecephys data from `aind-ecephys-nwb <https://github.com/AllenNeuralDynamics/aind-ecephys-nwb>`_
* Unit data from `aind-units-nwb <https://github.com/AllenNeuralDynamics/aind-units-nwb>`_

Features:

* Supports multiple streams (e.g., probes) per file
* Optional raw data and LFP data writing
* Configurable data compression and chunking (?)

Each step is containerized and can be deployed on various platforms while maintaining consistent processing standards.
