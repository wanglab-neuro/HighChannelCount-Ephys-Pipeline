# High Channel Count Ephys Pipeline
This branch is for Neuropixels data processing.

Useful links:
* [SpikeInterface](https://spikeinterface.readthedocs.io/en/latest/index.html)
* [IBL pipeline and protocols](https://www.internationalbrainlab.com/repro-ephys)

### Installation 
Create a `si_env` conda environment using:
`conda env create -f environment.yml`

Note: if using [containerized sorters](https://spikeinterface.readthedocs.io/en/latest/containerized_sorters.html), uncomment either `- docker` or `- spython`.

### Usage
In a terminal, navigate to the repository's `notebooks` folder, activate the `si_env` environment, then type `jupyter lab`.
From the browser window that pops up, run any notebook from that folder.

If running on a computing cluster, 
* unset the XDG variable: `unset XDG_RUNTIME_DIR`
* load singularity/apptainer (this is for the Openmind HPCC): 
```
source /etc/profile.d/modules.sh
module use /cm/shared/modulefiles
<!-- module load openmind8/anaconda -->
<!-- module load openmind/singularity/3.6.3 -->

``` 
* activate the environment: `conda activate si_env`
* navigate to the notebooks directory, e.g.: `cd /om2/user/$USER/code/HCCE_NPX/notebooks`
* then start jupyter specifying the part, e.g.: `jupyter lab --ip=0.0.0.0 --port=5000 --no-browser`.
* from a separate terminal, map the ports through ssh: `ssh -L 5000:node_#:5000 login@cluster`  

The notebooks will be available on https://localhost:5000/lab
 
To clear outputs for all notebooks in a directory:
`pip install nbconvert` (if needed)  
`find . -name "*.ipynb" -exec jupyter nbconvert --ClearOutputPreprocessor.enabled=True --inplace {} \;`
`git add .`  
`git commit -m "Cleared notebook outputs"`  

To run that automatically, add this to .git/hook/pre-commit:  
```
#!/bin/sh

# Clear outputs from all notebooks in the repository
find . -name "*.ipynb" -exec jupyter nbconvert --ClearOutputPreprocessor.enabled=True --inplace {} \;

# Stage the changes made by the clearing of outputs
git add $(git diff --name-only --cached | grep '\.ipynb$')

# Exit with success
exit 0
```
For Unix systems, make the `pre-commit` file executable: `chmod +x pre-commit`
