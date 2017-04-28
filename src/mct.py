#!/usr/bin/env python
from MulticoreTSNE import MulticoreTSNE as TSNE
import numpy as np

class mct():

	def __init__(self):
		self.X = None
		self.n_samples = None
		self.version_number = '0.0.5'

	def embed(self):
		X = np.array(self.X)
		self.X = X.reshape(int(self.n_samples),int(len(X)/self.n_samples))
		tsne = TSNE(n_jobs=4)
		R = tsne.fit_transform(self.X)
		return R
