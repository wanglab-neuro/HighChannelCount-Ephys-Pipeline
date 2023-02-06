# High Channel Count Ephys Pipeline
This branch is for Neuropixels data processing.

### Installation 
Create a `si_env` conda environment using:
`conda env create -f environment.yml`

Note: if using [containerized sorters](https://spikeinterface.readthedocs.io/en/latest/containerized_sorters.html), uncomment either `- docker` or `- spython`.

### Usage
In a terminal, navigate to the repository's `notebooks` folder, activate the `si_env` environment, then type `jupyter lab`.
From the browser window that pops up, run any notebook from that folder.

If running on a computing cluster, 
* unset the XDG variable: `unset XDG_RUNTIME_DIR`
* load Singularity (need 3.6+): `module load openmind/singularity/3.6.3` (this is for the Openmind HPCC). 
* activate the environment: `conda activate si_env`
* navigate to the notebooks directory, e.g.: `cd /om2/user/$USER/code/HCCE_NPX/notebooks`
* then start jupyter specifying the part, e.g.: `jupyter lab --ip=0.0.0.0 --port=5000 --no-browser`.
* from a separate terminal, map the ports through ssh: `ssh -L 5000:node_#:5000 login@cluster`  

The notebooks will be available on https://localhost:5000/lab
 


