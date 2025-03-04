Installation
============

Requirements
------------

The pipeline has different requirements depending on your deployment target. 
Here are the core requirements for each deployment option:

Local Deployment
~~~~~~~~~~~~~~~~

For local deployment, you need:

* ``nextflow`` (version 22.10.8 recommended)
* ``docker``
* ``figurl`` (optional, for cloud visualization)

SLURM Deployment
~~~~~~~~~~~~~~~~

For SLURM cluster deployment:

* ``nextflow`` (version 22.10.8 recommended)
* ``singularity`` or ``apptainer``
* Access to a SLURM cluster
* ``figurl`` (optional, for cloud visualization)

Installation Steps
------------------

Local Setup
~~~~~~~~~~~

1. Install Nextflow:

   Follow the `Nextflow installation guide <https://www.nextflow.io/docs/latest/install.html>`_

2. Install Docker:

   Follow the `Docker installation instructions <https://docs.docker.com/engine/install/>`_

3. (Optional) Set up Figurl:

   a. Install kachery-cloud:

   .. code-block:: bash

      pip install kachery-cloud

   b. Initialize kachery-cloud:

   .. code-block:: bash

      kachery-cloud-init

   c. Follow the printed URL and login with your GitHub account

   d. Create a new Client:
      
      * Go to https://kachery-gateway.figurl.org/?zone=default
      * Click on the "Client" tab
      * Add a new client (any label)

   e. Set credentials:
      
      * Click on the new client
      * Set environment variables:

      .. code-block:: bash

         export KACHERY_CLOUD_CLIENT_ID="your-client-id"
         export KACHERY_CLOUD_PRIVATE_KEY="your-private-key"
         # Optional: Set custom Kachery zone
         export KACHERY_ZONE="your-zone"

SLURM Setup
~~~~~~~~~~~

1. Install Nextflow on your cluster environment
2. Ensure Singularity/Apptainer is available
3. Set up environment variables:

   .. code-block:: bash

      # Optional: Set custom Singularity cache directory
      export NXF_SINGULARITY_CACHEDIR="/path/to/cache"

4. (Optional) Follow the same Figurl setup steps as in the local deployment

Clone the Repository
--------------------

Clone the pipeline repository:

.. code-block:: bash

   git clone https://github.com/AllenNeuralDynamics/aind-ephys-pipeline.git
   cd aind-ephys-pipeline/pipeline

The pipeline is now ready to be configured and run on your chosen platform.
