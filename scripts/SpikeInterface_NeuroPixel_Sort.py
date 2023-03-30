#!/usr/bin/env python
# coding: utf-8

# In[5]:


import spikeinterface as si
import spikeinterface.sorters as ss
import spikeinterface.extractors as se 
from pathlib import Path


# In[2]:


# base_folder = Path(r"/scratch2/weka/wanglab/prevosto/data/sc012/sc012_0123/sc012_0123_001")
# file_path = base_folder.joinpath("Record Node 101")

base_folder = Path(r"D:\Vincent\Data\sc014\sc014_0324\sc014_0324_001")
file_path = base_folder.joinpath("Record Node 101")


# In[8]:


from spikeinterface.core import ZarrRecordingExtractor


# In[17]:


zarr_folder = base_folder / "preprocessed.zarr"
recording_saved = ZarrRecordingExtractor(root_path=zarr_folder)
recording_saved


# In[12]:


recording_concat = si.concatenate_recordings([recording_saved])


# In[ ]:


# ss.get_default_sorter_params('spykingcircus')


# In[ ]:


# sorter_params = dict(n_jobs=40, chunk_duration="1s", progress_bar=True)


# In[ ]:


# sorting_SC = ss.run_spykingcircus(recording_concat, 
#              output_folder=base_folder / 'results_SC',
#              verbose=True, singularity_image="spikeinterface/spyking-circus-base:latest")


# In[ ]:


ss.get_default_sorter_params('pykilosort')


# In[18]:


sorter_params = dict(n_jobs=30)
# , chunk_duration="1s", progress_bar=True) already default


# In[ ]:


sorting_pyKS = ss.run_pykilosort(recording_saved,
                            output_folder=base_folder / 'results_pyKS',
                            verbose=True, docker_image="spikeinterface/pykilosort-base:latest",
                            **sorter_params)


# In[ ]:


# ss.get_default_sorter_params('tridesclous')


# In[ ]:


# sorting_TDC = ss.run_tridesclous(recording_concat,
#                             output_folder=base_folder / 'results_TDC',
#                             verbose=True, singularity_image=True) 
# # "spikeinterface/tridesclous-base:latest"


# In[ ]:


# ss.get_default_sorter_params('herdingspikes')


# In[ ]:


# sorter_params = dict(num_com_centers=2, detect_threshold=20,
#                 left_cutout_time=0.4, right_cutout_time=1.0,
#                 maa=0, amp_evaluation_time=0.1, spk_evaluation_time=0.4,
#                 ahpthr=0, decay_filtering=True, save_all=True)


# In[ ]:


# sorting_HS = ss.run_herdingspikes(recording_concat, 
#              output_folder=base_folder / 'results_HS',
#              verbose=True, singularity_image=True)
# # **sorter_params


# In[ ]:


# sorting_KS3 = ss.run_kilosort3(recording_concat, 
#                             output_folder=base_folder / 'results_KS3',
#                             verbose=True, singularity_image="spikeinterface/kilosort3-compiled-base:latest")


# In[ ]:


# sorting_KS2_5 = ss.run_kilosort2_5(recording_concat, 
#                             output_folder=base_folder / 'results_KS2_5',
#                             verbose=True, singularity_image="spikeinterface/kilosort2_5-compiled-base:latest")


# In[ ]:


# print(sorting_KS2_5)


# In[ ]:


# print(f'KS2.5 found {len(sorting_KS2_5.get_unit_ids())} units')


# In[ ]:


# sorting_KS2_5 = sorting_KS2_5.remove_empty_units()
# print(f'KS2.5 found {len(sorting_KS2_5.get_unit_ids())} non-empty units')


# In[ ]:


ss.get_default_sorter_params('mountainsort4')


# In[ ]:


sorter_params = dict(num_workers=40)


# In[ ]:


sorting_MS4 = ss.run_mountainsort4(recording_concat, 
              output_folder=base_folder / 'results_MS4',
              verbose=True, singularity_image="spikeinterface/mountainsort4-base:latest", 
              **sorter_params)


# In[ ]:


ss.get_default_sorter_params('ironclust')


# In[ ]:


sorter_params = dict(n_jobs=40, chunk_duration="1s", progress_bar=True)


# In[ ]:


sorting_IC = ss.run_ironclust(recording_concat, 
              output_folder=base_folder / 'results_IC',
              verbose=True, singularity_image="spikeinterface/ironclust-compiled-base:latest", 
              **sorter_params)


# ### Extract waveforms

# In[ ]:


recording_saved = si.load_extractor(base_folder / "preprocessed")
sorting = sorting_KS25
print(sorting)


# In[ ]:


get_ipython().run_line_magic('pinfo', 'si.extract_waveforms')


# In[ ]:


we = si.extract_waveforms(recording_saved, sorting, folder=base_folder / "waveforms", 
                          load_if_exists=False, overwrite=True, **job_kwargs)
print(we)


# In[ ]:


waveforms0 = we.get_waveforms(unit_id=0)
print(f"Waveforms shape: {waveforms0.shape}")
template0 = we.get_template(unit_id=0)
print(f"Template shape: {template0.shape}")
all_templates = we.get_all_templates()
print(f"All templates shape: {all_templates.shape}")


# In[ ]:


w = sw.plot_unit_templates(we, radius_um=30, backend="ipywidgets")


# In[ ]:


for unit in sorting.get_unit_ids():
    waveforms = we.get_waveforms(unit_id=unit)
    spiketrain = sorting.get_unit_spike_train(unit)
    print(f"Unit {unit} - num waveforms: {waveforms.shape[0]} - num spikes: {len(spiketrain)}")


# In[ ]:


we_all = si.extract_waveforms(recording_saved, sorting, folder=base_folder / "waveforms_all", 
                              max_spikes_per_unit=None,
                              overwrite=True,
                              **job_kwargs)


# In[ ]:


for unit in sorting.get_unit_ids():
    waveforms = we_all.get_waveforms(unit_id=unit)
    spiketrain = sorting.get_unit_spike_train(unit)
    print(f"Unit {unit} - num waveforms: {waveforms.shape[0]} - num spikes: {len(spiketrain)}")

