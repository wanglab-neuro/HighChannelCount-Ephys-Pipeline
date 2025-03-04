Customization
=============

The pipeline is designed to be flexible and customizable, given its modular structure.

There are two main customization points that we foresee: custom data ingestion and custom spike sorting.


1. Custom Data Ingestion
------------------------

To support additional data formats:

1. Create a custom job dispatch implementation (see `job dispatch README <https://github.com/AllenNeuralDynamics/aind-ephys-job-dispatch/>`_)
2. If additional dependencies are needed, create a custom Docker image that includes them
3. Modify ``main_local.nf`` or ``main_slurm.nf`` to use your custom job dispatch repo and container

This allows for flexible adaptation to different data formats while maintaining the pipeline's core functionality.

2. Custom Spike Sorting
-----------------------

To add a new spike sorting algorithm:

1. Create a custom spike sorting implementation (you can follow existing sorters as examples)
2. Create a new Docker image for your spike sorter, which should include the sorter installation and SpikeInterface
3. Modify the ``main_local.nf`` or ``main_slurm.nf`` to add a new channel:

.. code:: bash

    preprocessing_to_spikesort_newsorter = channel.create()

    ...

    if (sorter == 'kilosort25') {
	spikesort_to_postprocessing = spikesort_kilosort25_to_postprocessing
	spikesort_to_visualization = spikesort_kilosort25_to_visualization
	spikesort_to_results_collector = spikesort_kilosort25_to_results_collector
    }
    else if (sorter == 'kilosort4') {
        spikesort_to_postprocessing = spikesort_kilosort4_to_postprocessing
        spikesort_to_visualization = spikesort_kilosort4_to_visualization
        spikesort_to_results_collector = spikesort_kilosort4_to_results_collector
    }
    else if (sorter == 'spykingcircus2') {
        spikesort_to_postprocessing = spikesort_spykingcircus2_to_postprocessing
        spikesort_to_visualization = spikesort_spykingcircus2_to_visualization
        spikesort_to_results_collector = spikesort_spykingcircus2_to_results_collector
    }
    else if (sorter == 'new_sorter') {
        spikesort_to_postprocessing = spikesort_newsorter_to_postprocessing
        spikesort_to_visualization = spikesort_newsorter_to_visualization
        spikesort_to_results_collector = spikesort_newsorter_to_results_collector
    }

4. Add a new process in the  ``main_local.nf`` or ``main_slurm.nf`` to use your custom sorter repo and container (you can follow existing sorters as examples)
