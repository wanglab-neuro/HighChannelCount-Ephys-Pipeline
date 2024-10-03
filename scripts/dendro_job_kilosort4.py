from typing import List
import os
from dendro.client import submit_job
from dendro.client import DendroJob, DendroJobDefinition, DendroJobRequiredResources
from dendro.client import DendroJobOutputFile

# hello_neurosift : prepare_ephys_spike_sorting_dataset
# hello_kilosort4 : kilosort4
# hello_neurosift : spike_sorting_post_processing


def create_jobs():
    jobs: List[DendroJob] = []

    # Output for prepare_ephys_spike_sorting_dataset
    output_1 = DendroJobOutputFile(
        name='output',
        fileBaseName='pre.nwb.lindi.tar'
    )

    # Output for kilosort4
    output_2 = DendroJobOutputFile(
        name='output',
        fileBaseName='output.nwb.lindi.tar'
    )


    ##############################################
    # hello_neurosift : prepare_ephys_spike_sorting_dataset
    service_name = 'hello_world_service'
    app_name = 'hello_neurosift'
    processor_name = 'prepare_ephys_spike_sorting_dataset'
    job_def = DendroJobDefinition(
        appName=app_name,
        processorName=processor_name,
        inputFiles=[
            DendroJobInputFile(
                name='input',
                fileBaseName='input.nwb',
                url='https://api-staging.dandiarchive.org/api/assets/e2c4b638-86f0-405a-a36a-2b0b336d28f4/download/'
            ),
        ],
        outputFiles=[
            output_1,
        ],
        parameters=[
            DendroJobParameter(
                name='compression_ratio',
                value=0
            ),
            DendroJobParameter(
                name='duration_sec',
                value=1200
            ),
            DendroJobParameter(
                name='electrical_series_path',
                value="/acquisition/ElectricalSeries"
            ),
            DendroJobParameter(
                name='electrode_indices',
                value=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,357,358,359,360,361,362,363,364,365,366,367,368,369,370,371,372,373,374,375,376,377,378,379,380,381,382,383]
            ),
            DendroJobParameter(
                name='freq_max',
                value=6000
            ),
            DendroJobParameter(
                name='freq_min',
                value=300
            ),
            DendroJobParameter(
                name='output_electrical_series_name',
                value="ElectricalSeries_pre"
            ),
        ]
    )
    required_resources = DendroJobRequiredResources(
        numCpus=4,
        numGpus=0,
        memoryGb=4,
        timeSec=10800,
    )
    job = submit_job(
        service_name=service_name,
        job_definition=job_def,
        required_resources=required_resources,
        target_compute_client_ids=None,
        tags=['example'],
        skip_cache=False,
        rerun_failing=True,
        delete_failing=True
    )
    jobs.append(job)

    ##############################################
    # hello_kilosort4 : kilosort4
    service_name = 'hello_world_service'
    app_name = 'hello_kilosort4'
    processor_name = 'kilosort4'
    job_def = DendroJobDefinition(
        appName=app_name,
        processorName=processor_name,
        inputFiles=[
            DendroJobInputFile(
                name='input',
                fileBaseName='input.nwb.lindi.tar',
                url=output_1
            ),
        ],
        outputFiles=[
            output_2,
        ],
        parameters=[
            DendroJobParameter(
                name='electrical_series_path',
                value="acquisition/ElectricalSeries_pre"
            ),
            DendroJobParameter(
                name='output_units_name',
                value="units_kilosort4"
            ),
        ]
    )
    required_resources = DendroJobRequiredResources(
        numCpus=4,
        numGpus=1,
        memoryGb=16,
        timeSec=10800,
    )
    job = submit_job(
        service_name=service_name,
        job_definition=job_def,
        required_resources=required_resources,
        target_compute_client_ids=None,
        tags=['example'],
        skip_cache=False,
        rerun_failing=True,
        delete_failing=True
    )
    jobs.append(job)

    ##############################################
    # hello_neurosift : spike_sorting_post_processing
    service_name = 'hello_world_service'
    app_name = 'hello_neurosift'
    processor_name = 'spike_sorting_post_processing'
    job_def = DendroJobDefinition(
        appName=app_name,
        processorName=processor_name,
        inputFiles=[
            DendroJobInputFile(
                name='input',
                fileBaseName='input.nwb.lindi.tar',
                url=output_2
            ),
        ],
        outputFiles=[
            DendroJobOutputFile(
                name='output',
                fileBaseName='post.nwb.lindi.tar'
            ),
        ],
        parameters=[
            DendroJobParameter(
                name='electrical_series_path',
                value="acquisition/ElectricalSeries_pre"
            ),
            DendroJobParameter(
                name='units_path',
                value="processing/ecephys/units_kilosort4"
            ),
        ]
    )
    required_resources = DendroJobRequiredResources(
        numCpus=4,
        numGpus=0,
        memoryGb=4,
        timeSec=14400,
    )
    job = submit_job(
        service_name=service_name,
        job_definition=job_def,
        required_resources=required_resources,
        target_compute_client_ids=None,
        tags=['example'],
        skip_cache=False,
        rerun_failing=True,
        delete_failing=True
    )
    jobs.append(job)

    return jobs



if __name__ == '__main__':
    jobs = create_jobs()
    for job in jobs:
        print(f'{job.jobDefinition.appName} : {job.jobDefinition.processorName} : {job.job_url} : {job.status}')
