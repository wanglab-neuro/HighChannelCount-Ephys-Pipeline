#!/usr/bin/env python
# coding: utf-8

# In[11]:


import spikeinterface as si
import spikeinterface.extractors as se 
import spikeinterface.preprocessing as spre
import spikeinterface.widgets as sw


# In[2]:


import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

import warnings
warnings.simplefilter("ignore")

get_ipython().run_line_magic('matplotlib', 'widget')


# In[3]:


# base_folder = Path(r"/scratch2/weka/wanglab/prevosto/data/sc012/sc012_0123/sc012_0123_001")
# file_path = r"/scratch2/weka/wanglab/prevosto/data/sc012/sc012_0123/sc012_0123_001/Record Node 101"
base_folder = Path(r"D:\Vincent\Data\sc014\sc014_0324\sc014_0324_001")
file_path = r"D:\Vincent\Data\sc014\sc014_0324\sc014_0324_001\Record Node 101"


# In[5]:


recording = se.read_openephys(file_path, stream_id='1')


# In[6]:


# recording_baseline = si.SelectSegmentRecording(recording, segment_indices=0)


# In[ ]:


channel_ids = recording.get_channel_ids()
fs = recording.get_sampling_frequency()
num_chan = recording.get_num_channels()
num_segments = recording.get_num_segments()

print(f'Channel ids: {channel_ids}')
print(f'Sampling frequency: {fs}')
print(f'Number of channels: {num_chan}')
print(f"Number of segments: {num_segments}")


# In[8]:


probe = recording.get_probe()
print(probe)


# In[9]:


print(type(probe))


# In[ ]:


sw.plot_probe_map(recording)


# In[13]:


print("Properties:\n", list(recording.get_property_keys()))


# In[14]:


print(recording._properties.keys())


# ### Phase shift

# In[15]:


recording = spre.phase_shift(recording)


# ### High-pass filter

# In[16]:


recording_f = spre.highpass_filter(recording, freq_min=300)
# recording = spre.bandpass_filter(recording, freq_min=300, freq_max=6000)


# In[17]:


recording.annotate(is_filtered=False)
recording_f.annotate(is_filtered=True)


# ### Common Median Reference

# In[35]:


recording_baseline = si.SelectSegmentRecording(recording_f, segment_indices=0)
# recording_baseline = si.concatenate_recordings([recording_baseline])
recording_baseline


# In[39]:


recording_b_cmr = spre.common_reference(recording_baseline, reference='global', operator='median')


# In[ ]:


w = sw.plot_timeseries({"raw": recording, "filt": recording_f, "common": recording_b_cmr}, segment_index=0,
                        clim=(-50, 50), time_range=[10, 10.1], order_channel_by_depth=True,
                        backend="ipywidgets")


# In[38]:


job_kwargs = dict(n_jobs=10, chunk_duration="1s", progress_bar=True)


# In[41]:


# if (base_folder / "preprocessed").is_dir():
#     recording_saved = si.load_extractor(base_folder / "preprocessed")
# else:
# recording_saved = recording_cmr.save(folder=base_folder / "preprocessed", **job_kwargs)
    
recording_saved = recording_b_cmr.save(folder=base_folder / "preprocessed", format='zarr', **job_kwargs)


# If we inspect the `preprocessed` folder, we find that a few files have been saved. Let's take a look at what they are:

# In[42]:


recording_saved


# In[ ]:


# !ls {base_folder}\preprocessed


# In[ ]:


# print(f'Cached channels ids: {recording_saved.get_channel_ids()}')
# print(f'Channel groups after caching: {recording_saved.get_channel_groups()}')


# In[ ]:


# recording_loaded = si.load_extractor(base_folder / "preprocessed")


# In[ ]:


# print(f'Loaded channels ids: {recording_loaded.get_channel_ids()}')
# print(f'Channel groups after loading: {recording_loaded.get_channel_groups()}')


# In[ ]:


# w = sw.plot_timeseries({"preprocessed": recording_cmr, "saved": recording_saved, "loaded": recording_loaded},
#                         clim=(-50, 50), mode="line",
#                         backend="ipywidgets")

